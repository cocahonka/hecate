import 'package:meta/meta.dart';

@immutable
final class MessageEnvelope {
  final String nonce;
  final String ciphertext;
  final String tag;

  MessageEnvelope({
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });

  factory MessageEnvelope.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'nonce': final String nonce,
      'ciphertext': final String ciphertext,
      'tag': final String tag,
    } =>
      MessageEnvelope(nonce: nonce, ciphertext: ciphertext, tag: tag),
    _ => throw FormatException(
      'Invalid MessageEnvelope JSON',
      json,
    ),
  };

  Map<String, Object?> toJson() => {
    'nonce': nonce,
    'ciphertext': ciphertext,
    'tag': tag,
  };

  @override
  int get hashCode => Object.hash(nonce, ciphertext, tag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageEnvelope &&
          runtimeType == other.runtimeType &&
          nonce == other.nonce &&
          ciphertext == other.ciphertext &&
          tag == other.tag;

  @override
  String toString() =>
      'MessageEnvelope('
      'nonce: $nonce, '
      'ciphertext: $ciphertext, '
      'tag: $tag'
      ')';
}
