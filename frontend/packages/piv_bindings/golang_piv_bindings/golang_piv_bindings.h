/*
  golang_piv_bindings.h — public C header for the Go c-shared PIV bindings.
  All functions use a stable C ABI and return a status struct. On success
  (code = 0) out-parameters are populated. Any strings returned by functions
  must be freed by the caller using go_piv_bindings_free_string (or
  go_piv_bindings_free_string_array for arrays).
*/

#ifndef GOLANG_PIV_BINDINGS_H
#define GOLANG_PIV_BINDINGS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Handle of an opened device/session. Value 0 means "invalid".
typedef int64_t go_piv_bindings_handle_t;

// Unified status code for all calls.
// code: 0 = OK; non-zero values are error codes.
// message: optional human-readable message allocated by the library; must be freed
//          by the caller with go_piv_bindings_free_string when non-null.
typedef struct {
  int32_t code;
  const char* message;
} go_piv_bindings_status_t;

// Status codes (go_piv_bindings_status_t.code)
// 0  = OK
// 1  = NOT_PRESENT     (no readers/cards present)
// 2  = TRANSIENT       (temporary/IO/format error)
// 3  = INVALID_HANDLE  (session/handle not found)
// 4  = PIN_REQUIRED    (PIN missing/invalid)
// 5  = INVALID_INPUT   (invalid input/format)
// 6  = SLOT_EMPTY      (key/cert absent in slot)
// 7  = UNKNOWN_POLICY  (cannot determine slot policies)
// 8  = INTERNAL_ERROR  (internal processing error)

// Open the first available PIV device (or a device selected internally).
// On success, out_handle receives a valid non-zero handle.
go_piv_bindings_status_t go_piv_bindings_device_open(
  go_piv_bindings_handle_t* out_handle
);

// Close a previously opened device/session and release resources.
go_piv_bindings_status_t go_piv_bindings_device_close(
  go_piv_bindings_handle_t handle
);

// Helper to verify the PIV PIN once per session (allows YubiKey to cache PIN if policy permits).
// pin_utf8: null-terminated UTF-8 string; never persisted or logged by the implementation.
// Can be called at startup so subsequent operations do not require passing the PIN explicitly
// when the slot's PIN policy is Once. For Always policy, pass the PIN to operations directly.
go_piv_bindings_status_t go_piv_bindings_device_authenticate(
  go_piv_bindings_handle_t handle,
  const char* pin_utf8
);

// Query presence of keys in slots 9c and 9d and retrieve their public keys when present.
// out_has_9c / out_has_9d: 0 or 1.
// out_pk_9c_pem / out_pk_9d_pem: out-parameters for PEM-encoded SPKI public keys (null-terminated C-strings).
// When non-null on success, the library allocates each string; the caller MUST free them using
// go_piv_bindings_free_string to avoid memory leaks.
go_piv_bindings_status_t go_piv_bindings_piv_status(
  go_piv_bindings_handle_t handle,
  int32_t* out_has_9c,
  int32_t* out_has_9d,
  const char** out_pk_9c_pem,
  const char** out_pk_9d_pem
);


// Verify ES256 signature over SHA-256(challenge) using 9c public key supplied in PEM SPKI format.
// Inputs are base64url (no padding) for challenge and for signature (DER-encoded ECDSA signature in base64url).
go_piv_bindings_status_t go_piv_bindings_verify_signature_es256(
  const char* public_key_9c_pem,
  const char* challenge_base64url,
  const char* signature_der_base64url
);

// Sign an arbitrary challenge using slot 9c with ES256 (ECDSA P-256 + SHA-256).
// Inputs/outputs are base64url (no '=' padding).
// challenge_base64url: raw challenge bytes encoded as base64url.
// out_signature_der_base64url: DER-encoded ECDSA signature encoded as base64url; must be freed.
// pin_utf8_or_null: optional UTF-8 PIN; pass NULL when not needed (e.g., PINPolicyNever/Once after authenticate).
go_piv_bindings_status_t go_piv_bindings_sign_challenge(
  go_piv_bindings_handle_t handle,
  const char* challenge_base64url,
  const char** out_signature_der_base64url,
  const char* pin_utf8_or_null
);

// Wrap a freshly generated chat AES key for all recipients (including the initiator if provided).
// Output: an array of JSON strings (one per recipient), each describing the wrapped key object:
//   { "ephemeral_public_key_pem": "-----BEGIN PUBLIC KEY-----...", "wrapped_aes": "base64url" }
// The function does not expose the plaintext AES and clears it from memory after wrapping.
// The library allocates an array of length equal to recipients_count; the caller must free it with go_piv_bindings_free_string_array.
go_piv_bindings_status_t go_piv_bindings_wrap_aes_for_recipients(
  const char** recipients_pk_9d_pem,
  int32_t recipients_count,
  const char*** out_aes_envelope_json
);

// Encrypt a message using the chat AES key recovered from aes_envelope_json.
// aes_envelope_json: JSON returned by wrap for the current user: { "ephemeral_public_key_pem", "wrapped_aes" }.
// plaintext_base64url: plaintext in base64url.
// Output envelope_json: AES-GCM envelope JSON:
//   { "nonce": "base64url", "ciphertext": "base64url", "tag": "base64url" }
// pin_utf8_or_null: optional UTF-8 PIN; pass NULL when not needed (e.g., PINPolicyNever/Once after authenticate).
// The library allocates the string; the caller must free it with go_piv_bindings_free_string.
go_piv_bindings_status_t go_piv_bindings_encrypt_message(
  go_piv_bindings_handle_t handle,
  const char* aes_envelope_json,
  const char* plaintext_base64url,
  const char** out_message_envelope_json,
  const char* pin_utf8_or_null
);

// Decrypt a message using the chat AES key recovered from aes_envelope_json and the given message envelope JSON.
// pin_utf8_or_null: optional UTF-8 PIN; pass NULL when not needed (e.g., PINPolicyNever/Once after authenticate).
// Returns plaintext_base64url. The library allocates the string; the caller must free it with go_piv_bindings_free_string.
go_piv_bindings_status_t go_piv_bindings_decrypt_message(
  go_piv_bindings_handle_t handle,
  const char* aes_envelope_json,
  const char* envelope_json,
  const char** out_plaintext_base64url,
  const char* pin_utf8_or_null
);

// Query slot 9c policies. Returns numeric policies:
// out_pin_policy  : 0=Never, 1=Once, 2=Always
// out_touch_policy: 0=Never, 1=Always, 2=Cached
// If policies cannot be determined (e.g., attestation unsupported), returns status.code=7 (unknown policy).
go_piv_bindings_status_t go_piv_bindings_piv_slot9c_policy(
  go_piv_bindings_handle_t handle,
  int32_t* out_pin_policy,
  int32_t* out_touch_policy
);

// Query slot 9d policies. Returns numeric policies:
// out_pin_policy  : 0=Never, 1=Once, 2=Always
// out_touch_policy: 0=Never, 1=Always, 2=Cached
// If policies cannot be determined (e.g., attestation unsupported), returns status.code=7 (unknown policy).
go_piv_bindings_status_t go_piv_bindings_piv_slot9d_policy(
  go_piv_bindings_handle_t handle,
  int32_t* out_pin_policy,
  int32_t* out_touch_policy
);

// Free a single string previously allocated and returned by the library.
void go_piv_bindings_free_string(
  const char* string
);

// Free an array of strings previously allocated and returned by the library.
void go_piv_bindings_free_string_array(
  const char** array,
  int32_t length
);

#ifdef __cplusplus
}
#endif

#endif // GOLANG_PIV_BINDINGS_H


