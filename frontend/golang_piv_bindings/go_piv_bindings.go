package main

// #cgo CFLAGS: -DPIVGO
// #include <stdlib.h>
// #include <stdint.h>
// typedef int64_t go_piv_bindings_handle_t;
// typedef struct {
//   int32_t code;
//   const char* msg;
// } go_piv_bindings_status_t;
import "C"
import (
	"crypto"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"sync"
	"unsafe"

	pivlib "github.com/go-piv/piv-go/v2/piv"
)

type status struct {
	code int32
	msg  string
}

func ok() status                        { return status{0, ""} }
func err(code int32, msg string) status { return status{code, msg} }

func toCStatus(s status) C.go_piv_bindings_status_t {
	cmsg := (*C.char)(nil)
	if s.msg != "" {
		cmsg = C.CString(s.msg)
	}
	return C.go_piv_bindings_status_t{code: C.int32_t(s.code), msg: cmsg}
}

// error codes (mapped to status.code)
const (
	codeOK            int32 = 0
	codeNotPresent    int32 = 1 // no readers/cards present
	codeTransient     int32 = 2 // temporary pcsc error
	codeInvalidHandle int32 = 3 // handle not found
	codePinRequired   int32 = 4 // pin missing/invalid
	codeSlotEmpty     int32 = 6 // slot has no key/cert
	codeUnknownPolicy int32 = 7 // policy could not be determined
)

// simple global registry for open tokens (MVP)
var (
	mu                sync.Mutex
	nextHandle        int64 = 1
	handleToToken           = map[int64]*pivlib.YubiKey{}
	handlePinVerified       = map[int64]bool{}
)

func registerToken(yubiKey *pivlib.YubiKey) int64 {
	mu.Lock()
	defer mu.Unlock()
	handleValue := nextHandle
	nextHandle++
	handleToToken[handleValue] = yubiKey
	handlePinVerified[handleValue] = false
	return handleValue
}

func takeToken(handleValue int64) *pivlib.YubiKey {
	mu.Lock()
	defer mu.Unlock()
	token := handleToToken[handleValue]
	delete(handleToToken, handleValue)
	delete(handlePinVerified, handleValue)
	return token
}

func getToken(handleValue int64) (*pivlib.YubiKey, bool) {
	mu.Lock()
	defer mu.Unlock()
	token, exists := handleToToken[handleValue]
	return token, exists
}

//export go_piv_bindings_device_open
func go_piv_bindings_device_open(
	out *C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
	cards, errCards := pivlib.Cards()
	if errCards != nil {
		return toCStatus(err(codeTransient, "pcsc error"))
	}
	if len(cards) == 0 {
		return toCStatus(err(codeNotPresent, "no piv readers"))
	}
	var yubiKey *pivlib.YubiKey
	for _, readerName := range cards {
		if openedKey, openErr := pivlib.Open(readerName); openErr == nil && openedKey != nil {
			yubiKey = openedKey
			break
		}
	}
	if yubiKey == nil {
		return toCStatus(err(codeNotPresent, "no piv token openable"))
	}
	handleValue := registerToken(yubiKey)
	*out = C.go_piv_bindings_handle_t(handleValue)
	return toCStatus(ok())
}

//export go_piv_bindings_device_close
func go_piv_bindings_device_close(
	handle C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
	// idempotent close: remove if present, but always return OK
	handleValue := int64(handle)
	token := takeToken(handleValue)
	if token != nil {
		_ = token.Close()
	}
	return toCStatus(ok())
}

//export go_piv_bindings_device_authenticate
func go_piv_bindings_device_authenticate(
	handle C.go_piv_bindings_handle_t,
	pin *C.char,
) C.go_piv_bindings_status_t {
	handleValue := int64(handle)
	token, exists := getToken(handleValue)
	if !exists {
		return toCStatus(err(codeInvalidHandle, "invalid handle"))
	}
	if pin == nil || C.GoString(pin) == "" {
		return toCStatus(err(codePinRequired, "pin required"))
	}
	pinStr := C.GoString(pin)
	if _, metaErr := token.Metadata(pinStr); metaErr != nil {
		mu.Lock()
		handlePinVerified[handleValue] = false
		mu.Unlock()
		return toCStatus(err(codePinRequired, "pin invalid"))
	}
	mu.Lock()
	handlePinVerified[handleValue] = true
	mu.Unlock()
	return toCStatus(ok())
}

//export go_piv_bindings_piv_status
func go_piv_bindings_piv_status(
	handle C.go_piv_bindings_handle_t,
	has9c *C.int32_t,
	has9d *C.int32_t,
	pk9c **C.char,
	pk9d **C.char,
) C.go_piv_bindings_status_t {
	*has9c = 0
	*has9d = 0
	*pk9c = nil
	*pk9d = nil

	handleValue := int64(handle)
	token, found := getToken(handleValue)
	if !found {
		return toCStatus(err(codeInvalidHandle, "invalid handle"))
	}

	// helper: set has flag and PEM SPKI from source
	setPem := func(pubAny interface{}, has *C.int32_t, out **C.char) {
		if pubAny == nil {
			return
		}
		spki, _ := x509.MarshalPKIXPublicKey(pubAny)
		pemBytes := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: spki})
		if len(pemBytes) > 0 {
			*has = 1
			*out = C.CString(string(pemBytes))
		}
	}

	// Prefer attested pk for 9c (source of truth). Fallback to certificate.
	{
		var pub interface{}
		if attCert, e := token.AttestationCertificate(); e == nil && attCert != nil {
			if slotCert, e2 := token.Attest(pivlib.SlotSignature); e2 == nil && slotCert != nil {
				if _, vErr := pivlib.Verify(attCert, slotCert); vErr == nil {
					pub = slotCert.PublicKey
				}
			}
		}
		if pub == nil {
			if cert, e := token.Certificate(pivlib.SlotSignature); e == nil && cert != nil {
				pub = cert.PublicKey
			}
		}
		setPem(pub, has9c, pk9c)
	}

	// For 9d keep certificate path in MVP
	if cert, e := token.Certificate(pivlib.SlotKeyManagement); e == nil && cert != nil {
		setPem(cert.PublicKey, has9d, pk9d)
	}

	return toCStatus(ok())
}

//export go_piv_bindings_sign_challenge
func go_piv_bindings_sign_challenge(
	handle C.go_piv_bindings_handle_t,
	challenge *C.char,
	sig **C.char,
	pinOpt *C.char,
) C.go_piv_bindings_status_t {
	*sig = nil
	handleValue := int64(handle)
	token, exists := getToken(handleValue)
	if !exists {
		return toCStatus(err(codeInvalidHandle, "invalid handle"))
	}
	if challenge == nil {
		return toCStatus(err(codeTransient, "empty challenge"))
	}
	// Read certificate from 9c
	cert, certErr := token.Certificate(pivlib.SlotSignature)
	if certErr != nil || cert == nil {
		return toCStatus(err(codeSlotEmpty, "slot 9c empty"))
	}
	// Build auth (provide PIN only if previously verified)
	var auth pivlib.KeyAuth
	if pinOpt != nil {
		if p := C.GoString(pinOpt); p != "" {
			auth = pivlib.KeyAuth{PIN: p}
		}
	} else if handlePinVerified[handleValue] {
		// For PINPolicyOnce flows we already verified PIN via device_authenticate.
		auth = pivlib.KeyAuth{}
	}
	// Get signer for 9c
	signer, pkErr := token.PrivateKey(pivlib.SlotSignature, cert.PublicKey, auth)
	if pkErr != nil {
		return toCStatus(err(codePinRequired, "pin required"))
	}
	// Decode challenge (base64url no padding)
	challStr := C.GoString(challenge)
	challBytes, decErr := base64.RawURLEncoding.DecodeString(challStr)
	if decErr != nil {
		return toCStatus(err(codeTransient, "invalid base64url challenge"))
	}
	// Sign SHA-256(challenge)
	digest := sha256.Sum256(challBytes)
	derSig, signErr := signer.(crypto.Signer).Sign(rand.Reader, digest[:], crypto.SHA256)
	if signErr != nil {
		return toCStatus(err(codeTransient, "sign error: "+signErr.Error()))
	}
	// Return base64url encoded DER signature
	sigB64 := base64.RawURLEncoding.EncodeToString(derSig)
	*sig = C.CString(sigB64)
	return toCStatus(ok())
}

//export go_piv_bindings_wrap_aes_for_recipients
func go_piv_bindings_wrap_aes_for_recipients(
	recipients **C.char,
	n C.int32_t,
	encKeys ***C.char,
	encN *C.int32_t,
) C.go_piv_bindings_status_t {
	*encN = 0
	*encKeys = nil
	return toCStatus(ok())
}

//export go_piv_bindings_encrypt_message
func go_piv_bindings_encrypt_message(
	handle C.go_piv_bindings_handle_t,
	encAES *C.char,
	pt *C.char,
	aad *C.char,
	envelope **C.char,
) C.go_piv_bindings_status_t {
	*envelope = C.CString("{\"enc\":\"A256GCM\",\"iv\":\"\",\"ct\":\"\",\"tag\":\"\"}")
	return toCStatus(ok())
}

//export go_piv_bindings_decrypt_message
func go_piv_bindings_decrypt_message(
	handle C.go_piv_bindings_handle_t,
	encAES *C.char,
	envelope *C.char,
	pt **C.char,
) C.go_piv_bindings_status_t {
	*pt = C.CString("")
	return toCStatus(ok())
}

//export go_piv_bindings_piv_slot9c_policy
func go_piv_bindings_piv_slot9c_policy(
	handle C.go_piv_bindings_handle_t,
	pinPolicy *C.int32_t,
	touchPolicy *C.int32_t,
) C.go_piv_bindings_status_t {
	*pinPolicy = 0
	*touchPolicy = 0
	handleValue := int64(handle)
	token, exists := getToken(handleValue)
	if !exists {
		return toCStatus(err(codeInvalidHandle, "invalid handle"))
	}
	// Try attestation; if unsupported, return transient.
	attCert, attErr := token.AttestationCertificate()
	if attErr != nil || attCert == nil {
		return toCStatus(err(codeUnknownPolicy, "attestation cert unavailable"))
	}
	slotCert, slotErr := token.Attest(pivlib.SlotSignature)
	if slotErr != nil || slotCert == nil {
		return toCStatus(err(codeUnknownPolicy, "slot attestation unavailable"))
	}
	att, verifyErr := pivlib.Verify(attCert, slotCert)
	if verifyErr != nil {
		return toCStatus(err(codeUnknownPolicy, "attestation verify failed"))
	}
	// Map to int32 values per header doc
	switch att.PINPolicy {
	case pivlib.PINPolicyNever:
		*pinPolicy = 0
	case pivlib.PINPolicyOnce:
		*pinPolicy = 1
	case pivlib.PINPolicyAlways:
		*pinPolicy = 2
	default:
		return toCStatus(err(codeUnknownPolicy, "unknown pin policy"))
	}
	switch att.TouchPolicy {
	case pivlib.TouchPolicyNever:
		*touchPolicy = 0
	case pivlib.TouchPolicyAlways:
		*touchPolicy = 1
	case pivlib.TouchPolicyCached:
		*touchPolicy = 2
	default:
		return toCStatus(err(codeUnknownPolicy, "unknown touch policy"))
	}
	return toCStatus(ok())
}

//export go_piv_bindings_free_string
func go_piv_bindings_free_string(s *C.char) {
	if s != nil {
		C.free(unsafe.Pointer(s))
	}
}

//export go_piv_bindings_free_string_array
func go_piv_bindings_free_string_array(
	arr **C.char,
	n C.int32_t,
) {
	if arr == nil {
		return
	}
	slice := unsafe.Slice(arr, int(n))
	for _, p := range slice {
		if p != nil {
			C.free(unsafe.Pointer(p))
		}
	}
	C.free(unsafe.Pointer(arr))
}

func main() {}

//export go_piv_bindings_verify_signature_es256
func go_piv_bindings_verify_signature_es256(
	pkPem *C.char,
	challengeB64 *C.char,
	signatureDerB64 *C.char,
) C.go_piv_bindings_status_t {
	if pkPem == nil || C.GoString(pkPem) == "" {
		return toCStatus(err(codeTransient, "empty public key"))
	}
	if challengeB64 == nil || C.GoString(challengeB64) == "" {
		return toCStatus(err(codeTransient, "empty challenge"))
	}
	if signatureDerB64 == nil || C.GoString(signatureDerB64) == "" {
		return toCStatus(err(codeTransient, "empty signature"))
	}

	// Parse public key (PEM SPKI)
	pemBlock, _ := pem.Decode([]byte(C.GoString(pkPem)))
	if pemBlock == nil || pemBlock.Type != "PUBLIC KEY" {
		return toCStatus(err(codeTransient, "invalid public key pem"))
	}
	pubAny, perr := x509.ParsePKIXPublicKey(pemBlock.Bytes)
	if perr != nil {
		return toCStatus(err(codeTransient, "invalid public key spki"))
	}
	ecPub, parsed := pubAny.(*ecdsa.PublicKey)
	if !parsed || ecPub.Curve == nil {
		return toCStatus(err(codeTransient, "public key is not ecdsa p-256"))
	}

	// Decode inputs
	challStr := C.GoString(challengeB64)
	challBytes, decErr := base64.RawURLEncoding.DecodeString(challStr)
	if decErr != nil {
		return toCStatus(err(codeTransient, "invalid base64url challenge"))
	}
	sigStr := C.GoString(signatureDerB64)
	sigDer, sigDecErr := base64.RawURLEncoding.DecodeString(sigStr)
	if sigDecErr != nil {
		return toCStatus(err(codeTransient, "invalid base64url signature"))
	}

	// Hash and verify (DER signature)
	digest := sha256.Sum256(challBytes)
	if valid := ecdsa.VerifyASN1(ecPub, digest[:], sigDer); !valid {
		return toCStatus(err(codeTransient, "signature verification failed"))
	}
	return toCStatus(ok())
}
