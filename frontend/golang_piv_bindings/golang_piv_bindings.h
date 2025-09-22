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
// msg: optional human-readable message allocated by the library; must be freed
//      by the caller with go_piv_bindings_free_string when non-null.
typedef struct {
  int32_t code;
  const char* msg;
} go_piv_bindings_status_t;

// Open the first available PIV device (or a device selected internally).
// On success, out_handle receives a valid non-zero handle.
go_piv_bindings_status_t go_piv_bindings_device_open(go_piv_bindings_handle_t* out_handle);

// Close a previously opened device/session and release resources.
go_piv_bindings_status_t go_piv_bindings_device_close(go_piv_bindings_handle_t handle);

// Verify the PIV PIN once per session (if required by slot policy).
// pin_utf8: null-terminated UTF-8 string; not persisted or logged by the implementation.
go_piv_bindings_status_t go_piv_bindings_device_authenticate(go_piv_bindings_handle_t handle, const char* pin_utf8);

// Query presence of keys in slots 9c and 9d and retrieve their public keys when present.
// has_9c / has_9d: 0 or 1.
// pk_9c_pem / pk_9d_pem: PEM-encoded SPKI public keys; when non-null, the caller
// must free each string via go_piv_bindings_free_string.
go_piv_bindings_status_t go_piv_bindings_piv_status(
  go_piv_bindings_handle_t handle,
  int32_t* has_9c,
  int32_t* has_9d,
  const char** pk_9c_pem,
  const char** pk_9d_pem
);


// Verify ES256 signature over SHA-256(challenge) using 9c public key (PEM SPKI).
// Inputs are base64url (no padding) for challenge and signature (DER in base64url).
go_piv_bindings_status_t go_piv_bindings_verify_signature_es256(
  const char* pk_9c_pem,
  const char* challenge_b64url,
  const char* signature_der_b64url
);

// Sign an arbitrary challenge using slot 9c with ES256 (ECDSA P-256 + SHA-256).
// Inputs/outputs are base64url (no '=' padding).
// challenge_b64url: raw challenge bytes encoded as base64url.
// signature_b64url: DER-encoded ECDSA signature encoded as base64url; must be freed.
// pin_utf8_nullable: optional UTF-8 PIN; pass NULL when not needed (e.g., PINPolicyNever/Once after authenticate).
go_piv_bindings_status_t go_piv_bindings_sign_challenge(
  go_piv_bindings_handle_t handle,
  const char* challenge_b64url,
  const char** signature_b64url,
  const char* pin_utf8_nullable
);

// Generate an ephemeral AES-256 key and return one wrapped enc_aes per recipient using RSA-OAEP-256.
// recipients_pk_9d_pem: array of recipient 9d public keys (PEM SPKI), length recipients_len.
// enc_keys_b64url: array of base64url ciphertexts; caller must free via go_piv_bindings_free_string_array.
go_piv_bindings_status_t go_piv_bindings_wrap_aes_for_recipients(
  const char** recipients_pk_9d_pem,
  int32_t recipients_len,
  const char*** enc_keys_b64url,
  int32_t* enc_keys_len
);

// Encrypt a message using enc_aes (base64url). Optional AAD is also base64url.
// Returns a compact JSON envelope with fields enc="A256GCM", iv, ct, tag (all base64url); caller must free.
go_piv_bindings_status_t go_piv_bindings_encrypt_message(
  go_piv_bindings_handle_t handle,
  const char* enc_aes_b64url,
  const char* plaintext_b64url,
  const char* aad_b64url,
  const char** envelope_json
);

// Decrypt a JSON envelope using enc_aes (base64url). Returns plaintext in base64url; caller must free.
go_piv_bindings_status_t go_piv_bindings_decrypt_message(
  go_piv_bindings_handle_t handle,
  const char* enc_aes_b64url,
  const char* envelope_json,
  const char** plaintext_b64url
);

// Query slot 9c policies. Returns numeric policies:
// pin_policy  : 0=Never, 1=Once, 2=Always
// touch_policy: 0=Never, 1=Always, 2=Cached
// If policies cannot be determined (e.g., attestation unsupported), returns status.code=7 (unknown policy).
go_piv_bindings_status_t go_piv_bindings_piv_slot9c_policy(
  go_piv_bindings_handle_t handle,
  int32_t* pin_policy,
  int32_t* touch_policy
);

// Free a single string previously allocated and returned by the library.
void go_piv_bindings_free_string(const char* s);

// Free an array of strings previously allocated and returned by the library.
void go_piv_bindings_free_string_array(const char** arr, int32_t len);

#ifdef __cplusplus
}
#endif

#endif // GOLANG_PIV_BINDINGS_H


