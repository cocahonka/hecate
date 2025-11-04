import 'package:meta/meta.dart';

@immutable
final class AesEnvelope {
  final String ephemeralPublicKeyPem;
  final String wrappedAes;

  AesEnvelope({
    required this.ephemeralPublicKeyPem,
    required this.wrappedAes,
  });

  factory AesEnvelope.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'ephemeral_public_key_pem': final String ephemeralPublicKeyPem,
      'wrapped_aes': final String wrappedAes,
    } =>
      AesEnvelope(
        ephemeralPublicKeyPem: ephemeralPublicKeyPem,
        wrappedAes: wrappedAes,
      ),
    _ => throw FormatException(
      'Invalid AesEnvelope JSON',
      json,
    ),
  };

  Map<String, Object?> toJson() => {
    'ephemeral_public_key_pem': ephemeralPublicKeyPem,
    'wrapped_aes': wrappedAes,
  };

  @override
  int get hashCode => Object.hash(ephemeralPublicKeyPem, wrappedAes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AesEnvelope &&
          runtimeType == other.runtimeType &&
          ephemeralPublicKeyPem == other.ephemeralPublicKeyPem &&
          wrappedAes == other.wrappedAes;

  @override
  String toString() =>
      'AesEnvelope('
      'ephemeralPublicKeyPem: $ephemeralPublicKeyPem, '
      'wrappedAes: $wrappedAes'
      ')';
}
