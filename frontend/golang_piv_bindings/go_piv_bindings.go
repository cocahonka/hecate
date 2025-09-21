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
	"unsafe"
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

//export go_piv_bindings_device_open
func go_piv_bindings_device_open(
	out *C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
	*out = C.go_piv_bindings_handle_t(1)
	return toCStatus(ok())
}

//export go_piv_bindings_device_close
func go_piv_bindings_device_close(
	handle C.go_piv_bindings_handle_t,
) C.go_piv_bindings_status_t {
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
