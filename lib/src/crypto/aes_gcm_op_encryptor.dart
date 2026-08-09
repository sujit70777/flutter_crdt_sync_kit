import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../op/operation.dart';
import 'op_encryptor.dart';

/// End-to-end encrypts operation payloads with AES-256-GCM before they
/// leave the device, and decrypts them only after a [SyncAdapter.pull]
/// returns them.
///
/// The backend stores only ciphertext plus routing metadata
/// ([Operation.id], [docId], [hlc], [kind]) — it cannot read field values.
/// Every device that needs to read synced data must share [secretKey] out
/// of band (e.g. derived from a user passphrase, or distributed via your
/// own key-management flow); sync_kit does not manage key distribution.
class AesGcmOpEncryptor implements OpEncryptor {
  final SecretKey secretKey;
  final AesGcm _algorithm = AesGcm.with256bits();

  AesGcmOpEncryptor(this.secretKey);

  /// Derives a 256-bit key from a passphrase using PBKDF2. Convenient for
  /// demos; for production use, prefer a key generated and stored via a
  /// proper secrets manager (e.g. platform keychain/keystore).
  static Future<SecretKey> deriveKeyFromPassphrase(
    String passphrase, {
    required List<int> salt,
    int iterations = 200000,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  @override
  Future<Operation> encrypt(Operation op) async {
    final plaintext = utf8.encode(jsonEncode(op.value));
    final box = await _algorithm.encrypt(plaintext, secretKey: secretKey);
    return op.copyWith(
      value: base64Encode(box.concatenation()),
      clearValue: true,
    );
  }

  @override
  Future<Operation> decrypt(Operation op) async {
    final bytes = base64Decode(op.value as String);
    final box = SecretBox.fromConcatenation(
      bytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final plaintext = await _algorithm.decrypt(box, secretKey: secretKey);
    return op.copyWith(
      value: jsonDecode(utf8.decode(plaintext)),
      clearValue: true,
    );
  }
}
