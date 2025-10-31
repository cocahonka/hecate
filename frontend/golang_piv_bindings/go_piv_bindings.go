package main

// #include <stdlib.h>
// #include <stdint.h>
// typedef int64_t go_piv_bindings_handle_t;
// typedef struct {
//   int32_t code;
//   const char* message;
// } go_piv_bindings_status_t;
import "C"
import (
	"crypto"
	"crypto/aes"
	"crypto/ecdh"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"sync"
	"unsafe"

	josecipher "github.com/go-jose/go-jose/v4/cipher"
	pivlib "github.com/go-piv/piv-go/v2/piv"
	xhkdf "golang.org/x/crypto/hkdf"
)

func main() {}

type StatusCode int32

const (
	codeNotPresent    StatusCode = 1 // no readers/cards present
	codeTransient     StatusCode = 2 // temporary pcsc error
	codeInvalidHandle StatusCode = 3 // handle not found
	codePinRequired   StatusCode = 4 // pin missing/invalid
	codeInvalidInput  StatusCode = 5 // invalid input/format
	codeSlotEmpty     StatusCode = 6 // slot has no key/cert
	codeUnknownPolicy StatusCode = 7 // policy could not be determined
	codeInternalError StatusCode = 8 // internal processing error
)

func ok() C.go_piv_bindings_status_t {
	return C.go_piv_bindings_status_t{code: C.int32_t(0), message: nil}
}

func err(code StatusCode, message string) C.go_piv_bindings_status_t {
	cmessage := (*C.char)(nil)
	if message != "" {
		cmessage = C.CString(message)
	}
	return C.go_piv_bindings_status_t{code: C.int32_t(code), message: cmessage}
}

// simple global registry for open sessions (MVP)
var (
	globalMutex     sync.Mutex
	nextHandle      int64 = 1
	handleToSession       = map[int64]*Session{}
)

// session serializes operations per handle and carries PIN verification flag
type Session struct {
	yubiKey       *pivlib.YubiKey
	mutex         sync.Mutex
	isPinVerified bool
}

func registerSession(yubiKey *pivlib.YubiKey) int64 {
	globalMutex.Lock()
	defer globalMutex.Unlock()
	handleId := nextHandle
	nextHandle++
	handleToSession[handleId] = &Session{yubiKey: yubiKey}
	return handleId
}

func closeSession(handleId int64) *Session {
	globalMutex.Lock()
	defer globalMutex.Unlock()
	session := handleToSession[handleId]
	delete(handleToSession, handleId)
	return session
}

func getSession(handleId int64) (*Session, bool) {
	globalMutex.Lock()
	defer globalMutex.Unlock()
	session, exists := handleToSession[handleId]
	return session, exists
}

func validateHandleAndGetYubiKey(handle C.go_piv_bindings_handle_t) (*pivlib.YubiKey, *Session, C.go_piv_bindings_status_t) {
	handleId := int64(handle)
	session, exists := getSession(handleId)
	if !exists || session == nil {
		return nil, nil, err(codeInvalidHandle, "invalid handle")
	}
	session.mutex.Lock()
	yubiKey := session.yubiKey
	session.mutex.Unlock()
	if yubiKey == nil {
		return nil, nil, err(codeInvalidHandle, "invalid handle")
	}
	return yubiKey, session, ok()
}

//export go_piv_bindings_device_open
func go_piv_bindings_device_open(
	outHandle *C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
	cards, cardsErr := pivlib.Cards()
	if cardsErr != nil {
		return err(codeTransient, fmt.Sprintf("failed to enumerate card readers: %v", cardsErr))
	}
	if len(cards) == 0 {
		return err(codeNotPresent, "no card readers found")
	}

	var yubiKey *pivlib.YubiKey
	var lastOpenErr error
	for _, readerName := range cards {
		if openedKey, openErr := pivlib.Open(readerName); openErr == nil && openedKey != nil {
			yubiKey = openedKey
			break
		} else if openErr != nil {
			lastOpenErr = openErr
		}
	}

	if yubiKey == nil {
		if lastOpenErr != nil {
			return err(codeNotPresent, fmt.Sprintf("no PIV tokens available, last error: %v", lastOpenErr))
		}
		return err(codeNotPresent, "no PIV tokens found in available readers")
	}
	handleId := registerSession(yubiKey)
	*outHandle = C.go_piv_bindings_handle_t(handleId)
	return ok()
}

//export go_piv_bindings_device_close
func go_piv_bindings_device_close(
	handle C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
	// idempotent close: remove if present, but always return OK
	handleId := int64(handle)
	session := closeSession(handleId)
	if session != nil {
		session.mutex.Lock()
		if session.yubiKey != nil {
			_ = session.yubiKey.Close()
			session.yubiKey = nil
		}
		session.mutex.Unlock()
	}
	return ok()
}

//export go_piv_bindings_device_authenticate
func go_piv_bindings_device_authenticate(
	handle C.go_piv_bindings_handle_t,
	pinUtf8 *C.char,
) C.go_piv_bindings_status_t {
	if pinUtf8 == nil || C.GoString(pinUtf8) == "" {
		return err(codePinRequired, "PIN required")
	}

	yubiKey, session, status := validateHandleAndGetYubiKey(handle)
	if status.code != 0 {
		return status
	}

	pinString := C.GoString(pinUtf8)
	session.mutex.Lock()
	defer session.mutex.Unlock()

	if _, metadataErr := yubiKey.Metadata(pinString); metadataErr != nil {
		session.isPinVerified = false
		return err(codePinRequired, fmt.Sprintf("PIN verification failed: %v", metadataErr))
	}

	session.isPinVerified = true
	return ok()
}

//export go_piv_bindings_piv_status
func go_piv_bindings_piv_status(
	handle C.go_piv_bindings_handle_t,
	outHas9c *C.int32_t,
	outHas9d *C.int32_t,
	outPk9c **C.char,
	outPk9d **C.char,
) C.go_piv_bindings_status_t {
	*outHas9c = 0
	*outHas9d = 0
	*outPk9c = nil
	*outPk9d = nil

	yubiKey, _, status := validateHandleAndGetYubiKey(handle)
	if status.code != 0 {
		return status
	}

	// helper: set has flag and PEM SPKI from public key
	writePemPublicKey := func(publicKey interface{}, has *C.int32_t, out **C.char, slotName string) C.go_piv_bindings_status_t {
		if publicKey == nil {
			return ok()
		}
		spki, marshalErr := x509.MarshalPKIXPublicKey(publicKey)
		if marshalErr != nil {
			return err(codeInternalError, fmt.Sprintf("failed to marshal public key for %s: %v", slotName, marshalErr))
		}
		pemBytes := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: spki})
		if len(pemBytes) > 0 {
			*has = 1
			*out = C.CString(string(pemBytes))
		}
		return ok()
	}

	// get public key from slot 9c certificate (always use current certificate)
	if certificate, certificateErr := yubiKey.Certificate(pivlib.SlotSignature); certificateErr != nil {
		return err(codeTransient, fmt.Sprintf("failed to read certificate from slot 9c: %v", certificateErr))
	} else if certificate != nil {
		if status := writePemPublicKey(certificate.PublicKey, outHas9c, outPk9c, "slot 9c"); status.code != 0 {
			return status
		}
	}

	// get public key from slot 9d certificate
	if certificate, certificateErr := yubiKey.Certificate(pivlib.SlotKeyManagement); certificateErr != nil {
		return err(codeTransient, fmt.Sprintf("failed to read certificate from slot 9d: %v", certificateErr))
	} else if certificate != nil {
		if status := writePemPublicKey(certificate.PublicKey, outHas9d, outPk9d, "slot 9d"); status.code != 0 {
			return status
		}
	}

	return ok()
}

//export go_piv_bindings_sign_challenge
func go_piv_bindings_sign_challenge(
	handle C.go_piv_bindings_handle_t,
	challengeBase64url *C.char,
	outSignatureDerBase64url **C.char,
	pinUtf8OrNull *C.char,
) C.go_piv_bindings_status_t {
	*outSignatureDerBase64url = nil

	if challengeBase64url == nil {
		return err(codeInvalidInput, "empty challenge")
	}

	yubiKey, session, status := validateHandleAndGetYubiKey(handle)
	if status.code != 0 {
		return status
	}

	session.mutex.Lock()
	defer session.mutex.Unlock()

	// read certificate from slot 9c (signature slot)
	certificate, certificateErr := yubiKey.Certificate(pivlib.SlotSignature)
	if certificateErr != nil {
		return err(codeSlotEmpty, fmt.Sprintf("failed to read certificate from slot 9c: %v", certificateErr))
	}
	if certificate == nil {
		return err(codeSlotEmpty, "no certificate found in slot 9c")
	}

	// build authentication object based on PIN policy
	var auth pivlib.KeyAuth
	if pinUtf8OrNull != nil {
		if pinString := C.GoString(pinUtf8OrNull); pinString != "" {
			auth = pivlib.KeyAuth{PIN: pinString}
		}
	} else if session.isPinVerified {
		// for PINPolicyOnce flows we already verified PIN via device_authenticate
		auth = pivlib.KeyAuth{}
	}

	// get signer object for slot 9c private key
	signer, privateKeyErr := yubiKey.PrivateKey(pivlib.SlotSignature, certificate.PublicKey, auth)
	if privateKeyErr != nil {
		return err(codePinRequired, fmt.Sprintf("failed to access private key: %v", privateKeyErr))
	}

	// decode challenge from base64url (no padding)
	challengeString := C.GoString(challengeBase64url)
	challengeBytes, decodeErr := base64.RawURLEncoding.DecodeString(challengeString)
	if decodeErr != nil {
		return err(codeInvalidInput, fmt.Sprintf("failed to decode challenge from base64url: %v", decodeErr))
	}

	// sign SHA-256 hash of challenge data (ES256 algorithm)
	digest := sha256.Sum256(challengeBytes)
	derSignature, signErr := signer.(crypto.Signer).Sign(rand.Reader, digest[:], crypto.SHA256)
	if signErr != nil {
		return err(codeTransient, fmt.Sprintf("sign error: %v", signErr))
	}

	// return DER signature encoded as base64url
	signatureBase64url := base64.RawURLEncoding.EncodeToString(derSignature)
	*outSignatureDerBase64url = C.CString(signatureBase64url)
	return ok()
}

//export go_piv_bindings_wrap_aes_for_recipients
func go_piv_bindings_wrap_aes_for_recipients(
	recipientsPk9dPem **C.char,
	recipientsCount C.int32_t,
	outAesEnvelopeJson ***C.char,
) C.go_piv_bindings_status_t {
	if recipientsCount <= 0 || recipientsPk9dPem == nil || outAesEnvelopeJson == nil {
		return err(codeInvalidInput, "invalid recipients list")
	}

	// read recipient public keys
	type recipient struct {
		publicKey9d *ecdsa.PublicKey
	}
	rawRecipients := unsafe.Slice(recipientsPk9dPem, int(recipientsCount))
	recipients := make([]recipient, 0, len(rawRecipients))
	for i, cString := range rawRecipients {
		if cString == nil {
			return err(codeInvalidInput, fmt.Sprintf("recipient %d: empty public key", i))
		}
		pemBlock, _ := pem.Decode([]byte(C.GoString(cString)))
		if pemBlock == nil || pemBlock.Type != "PUBLIC KEY" {
			return err(codeInvalidInput, fmt.Sprintf("recipient %d: invalid public key pem", i))
		}
		anyPub, parseErr := x509.ParsePKIXPublicKey(pemBlock.Bytes)
		if parseErr != nil {
			return err(codeInvalidInput, fmt.Sprintf("recipient %d: invalid public key spki", i))
		}
		ecdsaPublicKey, okCast := anyPub.(*ecdsa.PublicKey)
		if !okCast || ecdsaPublicKey.Curve != elliptic.P256() {
			return err(codeInvalidInput, fmt.Sprintf("recipient %d: public key is not P-256", i))
		}
		recipients = append(recipients, recipient{publicKey9d: ecdsaPublicKey})
	}

	// generate chat AES key (32 bytes)
	chatAES := make([]byte, 32)
	if _, errRand := rand.Read(chatAES); errRand != nil {
		return err(codeInternalError, fmt.Sprintf("failed to generate AES key: %v", errRand))
	}
	defer zeroize(chatAES)

	// generate single ephemeral EC P-256 keypair
	ecdhGroup := ecdh.P256()
	ephemeralPrivateKey, ephermalErr := ecdhGroup.GenerateKey(rand.Reader)
	if ephermalErr != nil {
		return err(codeInternalError, fmt.Sprintf("failed to generate ephemeral key: %v", ephermalErr))
	}

	// build PEM(SPKI) for ephemeral public key
	spki, spkiErr := x509.MarshalPKIXPublicKey(ephemeralPrivateKey.PublicKey())
	if spkiErr != nil {
		return err(codeInternalError, fmt.Sprintf("failed to marshal ephemeral public key: %v", spkiErr))
	}
	pemBytes := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: spki})
	if len(pemBytes) == 0 {
		return err(codeInternalError, "failed to encode ephemeral public key pem")
	}
	ephemeralPublicKeyPem := string(pemBytes)

	// prepare output C array
	outSlice := make([]*C.char, len(recipients))
	outSliceCleanup := func() {
		for _, p := range outSlice {
			if p != nil {
				C.free(unsafe.Pointer(p))
			}
		}
	}

	// wrap chatAES for each recipient
	for i, recipient := range recipients {
		// convert recipient ECDSA public key to ECDH public key
		ecdhRecipientPublicKey, newPubErr := recipient.publicKey9d.ECDH()
		if newPubErr != nil {
			outSliceCleanup()
			return err(codeInvalidInput, fmt.Sprintf("invalid recipient public key for ecdh: %v", newPubErr))
		}

		// ECDH shared secret
		shared, ecdhErr := ephemeralPrivateKey.ECDH(ecdhRecipientPublicKey)
		defer zeroize(shared)
		if ecdhErr != nil {
			outSliceCleanup()
			return err(codeInternalError, fmt.Sprintf("ecdh failed: %v", ecdhErr))
		}

		// derive KEK via HKDF-SHA256
		reader := xhkdf.New(sha256.New, shared, nil, nil)
		kek := make([]byte, 32)
		defer zeroize(kek)
		if _, readErr := io.ReadFull(reader, kek); readErr != nil {
			outSliceCleanup()
			return err(codeInternalError, fmt.Sprintf("hkdf failed: %v", readErr))
		}

		// AES Key Wrap (RFC 3394) of chatAES under KEK
		cipherBlock, newCipherErr := aes.NewCipher(kek)
		if newCipherErr != nil {
			outSliceCleanup()
			return err(codeInternalError, fmt.Sprintf("aes cipher init failed: %v", newCipherErr))
		}
		wrapped, wrapErr := josecipher.KeyWrap(cipherBlock, chatAES)
		defer zeroize(wrapped)
		if wrapErr != nil {
			outSliceCleanup()
			return err(codeInternalError, fmt.Sprintf("aes key wrap failed: %v", wrapErr))
		}

		// build JSON payload
		payload := struct {
			EphemeralPublicKeyPEM string `json:"ephemeral_public_key_pem"`
			WrappedAES            string `json:"wrapped_aes"`
		}{
			EphemeralPublicKeyPEM: ephemeralPublicKeyPem,
			WrappedAES:            base64.RawURLEncoding.EncodeToString(wrapped),
		}

		jsonBytes, jsonErr := json.Marshal(payload)
		if jsonErr != nil {
			outSliceCleanup()
			return err(codeInternalError, fmt.Sprintf("json marshal failed: %v", jsonErr))
		}
		outSlice[i] = C.CString(string(jsonBytes))
	}

	// allocate C array and copy pointers
	total := C.size_t(len(outSlice))
	elementSize := C.size_t(unsafe.Sizeof(uintptr(0)))
	array := (**C.char)(C.malloc(elementSize * total))
	if array == nil {
		outSliceCleanup()
		return err(codeInternalError, "allocation failed")
	}
	arraySlice := unsafe.Slice(array, int(total))
	copy(arraySlice, outSlice)
	*outAesEnvelopeJson = array
	return ok()
}

//export go_piv_bindings_encrypt_message
func go_piv_bindings_encrypt_message(
	handle C.go_piv_bindings_handle_t,
	aesEnvelopeJson *C.char,
	plaintextBase64url *C.char,
	outMessageEnvelopeJson **C.char,
	pinUtf8OrNull *C.char,
) C.go_piv_bindings_status_t {
	return ok()
}

//export go_piv_bindings_decrypt_message
func go_piv_bindings_decrypt_message(
	handle C.go_piv_bindings_handle_t,
	aesEnvelopeJson *C.char,
	envelopeJson *C.char,
	outPlaintextBase64url **C.char,
	pinUtf8OrNull *C.char,
) C.go_piv_bindings_status_t {
	return ok()
}

//export go_piv_bindings_piv_slot9c_policy
func go_piv_bindings_piv_slot9c_policy(
	handle C.go_piv_bindings_handle_t,
	outPinPolicy *C.int32_t,
	outTouchPolicy *C.int32_t,
) C.go_piv_bindings_status_t {
	*outPinPolicy = 0
	*outTouchPolicy = 0

	yubiKey, _, status := validateHandleAndGetYubiKey(handle)
	if status.code != 0 {
		return status
	}

	// get attestation certificate
	attestationCertificate, attestationErr := yubiKey.AttestationCertificate()
	if attestationErr != nil || attestationCertificate == nil {
		return err(codeUnknownPolicy, "attestation cert unavailable")
	}

	// get slot attestation certificate
	slotCertificate, slotErr := yubiKey.Attest(pivlib.SlotSignature)
	if slotErr != nil || slotCertificate == nil {
		return err(codeUnknownPolicy, "slot attestation unavailable")
	}

	// verify attestation certificate
	attestation, verifyErr := pivlib.Verify(attestationCertificate, slotCertificate)
	if verifyErr != nil {
		return err(codeUnknownPolicy, "attestation verify failed")
	}

	switch attestation.PINPolicy {
	case pivlib.PINPolicyNever:
		*outPinPolicy = 0
	case pivlib.PINPolicyOnce:
		*outPinPolicy = 1
	case pivlib.PINPolicyAlways:
		*outPinPolicy = 2
	default:
		return err(codeUnknownPolicy, "unknown pin policy")
	}
	switch attestation.TouchPolicy {
	case pivlib.TouchPolicyNever:
		*outTouchPolicy = 0
	case pivlib.TouchPolicyAlways:
		*outTouchPolicy = 1
	case pivlib.TouchPolicyCached:
		*outTouchPolicy = 2
	default:
		return err(codeUnknownPolicy, "unknown touch policy")
	}
	return ok()
}

//export go_piv_bindings_verify_signature_es256
func go_piv_bindings_verify_signature_es256(
	publicKey9cPem *C.char,
	challengeBase64url *C.char,
	signatureDerBase64url *C.char,
) C.go_piv_bindings_status_t {
	if publicKey9cPem == nil || C.GoString(publicKey9cPem) == "" {
		return err(codeInvalidInput, "empty public key")
	}
	if challengeBase64url == nil || C.GoString(challengeBase64url) == "" {
		return err(codeInvalidInput, "empty challenge")
	}
	if signatureDerBase64url == nil || C.GoString(signatureDerBase64url) == "" {
		return err(codeInvalidInput, "empty signature")
	}

	// parse public key (PEM SPKI)
	pemBlock, _ := pem.Decode([]byte(C.GoString(publicKey9cPem)))
	if pemBlock == nil || pemBlock.Type != "PUBLIC KEY" {
		return err(codeInvalidInput, "invalid public key pem")
	}
	publicKeyAny, parseErr := x509.ParsePKIXPublicKey(pemBlock.Bytes)
	if parseErr != nil {
		return err(codeInvalidInput, "invalid public key spki")
	}
	ecdsaPublicKey, isEcdsa := publicKeyAny.(*ecdsa.PublicKey)
	if !isEcdsa || ecdsaPublicKey.Curve == nil {
		return err(codeInvalidInput, "public key is not ecdsa p-256")
	}

	// decode inputs
	challengeString := C.GoString(challengeBase64url)
	challengeBytes, challengeDecodeErr := base64.RawURLEncoding.DecodeString(challengeString)
	if challengeDecodeErr != nil {
		return err(codeInvalidInput, "invalid base64url challenge")
	}
	signatureString := C.GoString(signatureDerBase64url)
	signatureDer, signatureDecodeErr := base64.RawURLEncoding.DecodeString(signatureString)
	if signatureDecodeErr != nil {
		return err(codeInvalidInput, "invalid base64url signature")
	}

	// hash and verify (DER signature)
	digest := sha256.Sum256(challengeBytes)
	if isValid := ecdsa.VerifyASN1(ecdsaPublicKey, digest[:], signatureDer); !isValid {
		return err(codeTransient, "signature verification failed")
	}
	return ok()
}

//export go_piv_bindings_free_string
func go_piv_bindings_free_string(string *C.char) {
	if string != nil {
		C.free(unsafe.Pointer(string))
	}
}

//export go_piv_bindings_free_string_array
func go_piv_bindings_free_string_array(
	array **C.char,
	length C.int32_t,
) {
	if array == nil {
		return
	}
	slice := unsafe.Slice(array, int(length))
	for _, p := range slice {
		if p != nil {
			C.free(unsafe.Pointer(p))
		}
	}
	C.free(unsafe.Pointer(array))
}

func zeroize(bytes []byte) {
	if bytes == nil {
		return
	}
	for i := range bytes {
		bytes[i] = 0
	}
}

// parses AES envelope JSON and attempts to unwrap chat AES using YubiKey slot 9d.
// Returns a 32-byte AES key on success and status.code=0, otherwise returns nil and error status.
func deriveChatAESFromEnvelopeJSON(
	handle C.go_piv_bindings_handle_t,
	aesEnvelopeJson *C.char,
	pinUtf8OrNull *C.char,
) ([]byte, C.go_piv_bindings_status_t) {
	if aesEnvelopeJson == nil || C.GoString(aesEnvelopeJson) == "" {
		return nil, err(codeInvalidInput, "empty aes_envelope_json")
	}

	// parse JSON
	var parsed struct {
		EphemeralPublicKeyPEM string `json:"ephemeral_public_key_pem"`
		WrappedAES            string `json:"wrapped_aes"`
	}
	if unmarshalErr := json.Unmarshal([]byte(C.GoString(aesEnvelopeJson)), &parsed); unmarshalErr != nil {
		return nil, err(codeInvalidInput, fmt.Sprintf("invalid aes_envelope_json: %v", unmarshalErr))
	}
	if parsed.EphemeralPublicKeyPEM == "" || parsed.WrappedAES == "" {
		return nil, err(codeInvalidInput, "missing fields in aes_envelope_json")
	}

	// decode wrapped key
	wrappedBytes, base64Err := base64.RawURLEncoding.DecodeString(parsed.WrappedAES)
	if base64Err != nil {
		return nil, err(codeInvalidInput, fmt.Sprintf("invalid wrapped_aes (base64url): %v", base64Err))
	}
	if len(wrappedBytes) < 16 || len(wrappedBytes)%8 != 0 {
		return nil, err(codeInvalidInput, fmt.Sprintf("invalid wrapped_aes length: %d", len(wrappedBytes)))
	}
	defer zeroize(wrappedBytes)

	// parse ephemeral public key PEM -> ECDSA -> ECDH public key (uncompressed 0x04||X||Y)
	pemBlock, _ := pem.Decode([]byte(parsed.EphemeralPublicKeyPEM))
	if pemBlock == nil || pemBlock.Type != "PUBLIC KEY" {
		return nil, err(codeInvalidInput, "invalid ephemeral_public_key_pem")
	}
	anyPub, parseErr := x509.ParsePKIXPublicKey(pemBlock.Bytes)
	if parseErr != nil {
		return nil, err(codeInternalError, fmt.Sprintf("invalid ephemeral spki: %v", parseErr))
	}
	ephECDSAPub, isECDSA := anyPub.(*ecdsa.PublicKey)
	if !isECDSA || ephECDSAPub.Curve != elliptic.P256() {
		return nil, err(codeInvalidInput, "ephemeral public key is not P-256")
	}

	// convert ephemeral ECDSA public key to ECDH public key
	peerECDH, peerConvertErr := ephECDSAPub.ECDH()
	if peerConvertErr != nil {
		return nil, err(codeInternalError, fmt.Sprintf("invalid ephemeral public key: %v", peerConvertErr))
	}

	// obtain shared secret via YubiKey 9d (ECDH) using P-256
	yubiKey, session, status := validateHandleAndGetYubiKey(handle)
	if status.code != 0 {
		return nil, status
	}
	session.mutex.Lock()
	defer session.mutex.Unlock()

	// fetch 9d certificate to bind the private key object
	certificate9d, certificateErr := yubiKey.Certificate(pivlib.SlotKeyManagement)
	if certificateErr != nil || certificate9d == nil {
		return nil, err(codeSlotEmpty, fmt.Sprintf("failed to read certificate from slot 9d: %v", certificateErr))
	}
	if pk, ok := certificate9d.PublicKey.(*ecdsa.PublicKey); !ok || pk.Curve != elliptic.P256() {
		return nil, err(codeInternalError, "slot 9d certificate is not ECDSA P-256")
	}

	// build auth
	var keyAuth pivlib.KeyAuth
	if pinUtf8OrNull != nil {
		if pinString := C.GoString(pinUtf8OrNull); pinString != "" {
			keyAuth = pivlib.KeyAuth{PIN: pinString}
		}
	} else if session.isPinVerified {
		keyAuth = pivlib.KeyAuth{}
	}
	privateKeyAny, privateKeyErr := yubiKey.PrivateKey(pivlib.SlotKeyManagement, certificate9d.PublicKey, keyAuth)
	if privateKeyErr != nil || privateKeyAny == nil {
		return nil, err(codePinRequired, fmt.Sprintf("failed to access key 9d: %v", privateKeyErr))
	}

	// type assert to piv ECDSAPrivateKey to call ECDH
	ecdsaPrivateKey, isECDSAPrivateKey := privateKeyAny.(*pivlib.ECDSAPrivateKey)
	if !isECDSAPrivateKey {
		return nil, err(codeInternalError, "slot 9d is not ECDSA P-256 key")
	}
	shared, ecdhErr := ecdsaPrivateKey.ECDH(peerECDH)
	if ecdhErr != nil || len(shared) == 0 {
		return nil, err(codeInternalError, fmt.Sprintf("ecdh failed: %v", ecdhErr))
	}
	defer zeroize(shared)

	// derive KEK via HKDF-SHA256 — MUST match wrap side parameters exactly.
	reader := xhkdf.New(sha256.New, shared, nil, nil)
	kek := make([]byte, 32)
	if _, readErr := io.ReadFull(reader, kek); readErr != nil {
		return nil, err(codeInternalError, fmt.Sprintf("hkdf failed: %v", readErr))
	}
	defer zeroize(kek)

	// unwrap chat AES via josecipher (RFC3394)
	cipherBlock, newCipherErr := aes.NewCipher(kek)
	if newCipherErr != nil {
		return nil, err(codeInternalError, fmt.Sprintf("aes cipher init failed: %v", newCipherErr))
	}
	chatAES, unwrapErr := josecipher.KeyUnwrap(cipherBlock, wrappedBytes)
	if unwrapErr != nil || len(chatAES) != 32 {
		if chatAES != nil {
			zeroize(chatAES)
		}
		return nil, err(codeInternalError, fmt.Sprintf("aes key unwrap failed: %v", unwrapErr))
	}

	// caller MUST zeroize chatAES after use
	return chatAES, ok()
}
