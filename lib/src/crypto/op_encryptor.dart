import '../op/operation.dart';

/// Encrypts/decrypts an [Operation]'s payload at the sync boundary.
///
/// [SyncEngine] calls [encrypt] on every operation immediately before
/// handing it to a [SyncAdapter.push], and [decrypt] on every operation
/// immediately after a [SyncAdapter.pull], before it is stored or merged.
/// The op log on disk (via [LocalStore]) and every in-process CRDT merge
/// always see plaintext values — only what actually leaves the device over
/// the network is encrypted. A backend using this is structurally unable
/// to read field values, only routing metadata ([Operation.id],
/// [Operation.docId], [Operation.hlc], [Operation.kind]).
abstract class OpEncryptor {
  /// Returns a copy of [op] with [Operation.value] replaced by its
  /// encrypted form (typically a base64 ciphertext string).
  Future<Operation> encrypt(Operation op);

  /// Reverses [encrypt].
  Future<Operation> decrypt(Operation op);
}

/// The default [OpEncryptor]: a no-op passthrough. Use [AesGcmOpEncryptor]
/// (or your own implementation) to enable end-to-end encryption of the op
/// log in transit.
class NoopOpEncryptor implements OpEncryptor {
  const NoopOpEncryptor();

  @override
  Future<Operation> encrypt(Operation op) async => op;

  @override
  Future<Operation> decrypt(Operation op) async => op;
}
