/// The kind of CRDT mutation an [Operation] carries.
///
/// The [Operation] envelope is shared by every CRDT type; `kind` tells the
/// merge layer which algorithm to apply.
enum OpKind {
  /// Last-Write-Wins register set: replaces a document field's value.
  /// Payload: the raw field value (any JSON-encodable value, or `null`).
  lwwSet,

  /// G-Counter/PN-Counter increment. Payload: a non-negative `num` delta.
  counterIncrement,

  /// PN-Counter decrement. Payload: a non-negative `num` delta.
  counterDecrement,

  /// OR-Set add. The operation's own [Operation.id] is the unique "tag" for
  /// this add, per the observed-remove-set algorithm. Payload: the element.
  setAdd,

  /// OR-Set remove. Payload: a `List<String>` of the add-tags (operation
  /// ids) being observed-removed.
  setRemove,
}

/// Serializes an [OpKind] to its compact wire/storage name.
extension OpKindCodec on OpKind {
  String get wireName => switch (this) {
    OpKind.lwwSet => 'lww_set',
    OpKind.counterIncrement => 'counter_inc',
    OpKind.counterDecrement => 'counter_dec',
    OpKind.setAdd => 'set_add',
    OpKind.setRemove => 'set_remove',
  };

  static OpKind fromWireName(String name) => switch (name) {
    'lww_set' => OpKind.lwwSet,
    'counter_inc' => OpKind.counterIncrement,
    'counter_dec' => OpKind.counterDecrement,
    'set_add' => OpKind.setAdd,
    'set_remove' => OpKind.setRemove,
    _ => throw FormatException('Unknown OpKind wire name: $name'),
  };
}
