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
	"crypto/x509"
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
)

// simple global registry for open tokens (MVP)
var (
	mu            sync.Mutex
	nextHandle    int64 = 1
	handleToToken       = map[int64]*pivlib.YubiKey{}
)

func registerToken(yubiKey *pivlib.YubiKey) int64 {
	mu.Lock()
	defer mu.Unlock()
	handleValue := nextHandle
	nextHandle++
	handleToToken[handleValue] = yubiKey
	return handleValue
}

func takeToken(handleValue int64) *pivlib.YubiKey {
	mu.Lock()
	defer mu.Unlock()
	token := handleToToken[handleValue]
	delete(handleToToken, handleValue)
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

	// helper: set has flag and PEM SPKI from certificate if present
	setFromCert := func(slot pivlib.Slot, has *C.int32_t, out **C.char) {
		if cert, e := token.Certificate(slot); e == nil && cert != nil {
			*has = 1
			spki, _ := x509.MarshalPKIXPublicKey(cert.PublicKey)
			pemBytes := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: spki})
			if len(pemBytes) > 0 {
				*out = C.CString(string(pemBytes))
			}
		}
	}

	setFromCert(pivlib.SlotSignature, has9c, pk9c)     // 9c
	setFromCert(pivlib.SlotKeyManagement, has9d, pk9d) // 9d

	return toCStatus(ok())
}

//export go_piv_bindings_sign_challenge
func go_piv_bindings_sign_challenge(
	handle C.go_piv_bindings_handle_t,
	challenge *C.char,
	sig **C.char,
) C.go_piv_bindings_status_t {
	*sig = C.CString("")
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
