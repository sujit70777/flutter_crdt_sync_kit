/// Converts a typed model `T` to and from a flat field map, so
/// [SyncedDoc] can track each field as an independent LWW-Register CRDT.
///
/// A field-level (rather than whole-document) LWW register is what lets
/// two offline edits to *different* fields of the same record merge
/// without either one clobbering the other — only genuinely concurrent
/// writes to the *same* field compete, and the one with the greater [Hlc]
/// wins.
abstract class DocumentCodec<T> {
  const DocumentCodec();

  /// Flattens [value] into a JSON-encodable field map. Keys are field
  /// names; values become the payload of `lwwSet` operations, so they must
  /// be JSON-encodable (or `null`).
  Map<String, Object?> toFields(T value);

  /// Rebuilds a `T` from a field map produced by merging `lwwSet`
  /// operations. Every key from [toFields] is guaranteed to be present,
  /// using the constructor's `empty` value's fields for any never written.
  T fromFields(Map<String, Object?> fields);

  /// Builds a codec from a pair of plain functions — the common case when
  /// `T` already has `toJson`/`fromJson`-style conversions (e.g. generated
  /// by `json_serializable` or hand-written `copyWith`-based models).
  const factory DocumentCodec.functional({
    required Map<String, Object?> Function(T value) toFields,
    required T Function(Map<String, Object?> fields) fromFields,
  }) = _FunctionalDocumentCodec<T>;
}

class _FunctionalDocumentCodec<T> extends DocumentCodec<T> {
  final Map<String, Object?> Function(T value) _toFields;
  final T Function(Map<String, Object?> fields) _fromFields;

  const _FunctionalDocumentCodec({
    required Map<String, Object?> Function(T value) toFields,
    required T Function(Map<String, Object?> fields) fromFields,
  }) : _toFields = toFields,
       _fromFields = fromFields;

  @override
  Map<String, Object?> toFields(T value) => _toFields(value);

  @override
  T fromFields(Map<String, Object?> fields) => _fromFields(fields);
}
