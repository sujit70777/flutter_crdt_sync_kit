import 'package:meta/meta.dart';

import '../crdt/hlc.dart';
import 'op_kind.dart';

/// A single, immutable CRDT mutation: the unit of work in sync_kit's
/// op-based log.
///
/// Every local write is captured as an [Operation] rather than as a final
/// value. This is what makes merging safe: two nodes that generated
/// different operations while offline can each replay the *other's*
/// operations against their own state and always converge on the same
/// result, regardless of the order operations are received in.
///
/// [id] must be globally unique (a UUID) and is used both as the
/// idempotency key (so applying the same operation twice is a no-op) and,
/// for [OpKind.setAdd], as the OR-Set element tag.
@immutable
class Operation {
  /// Globally unique id for this operation (UUID v4 recommended).
  final String id;

  /// Id of the document/collection/counter this operation targets.
  final String docId;

  /// A user-defined type tag for [docId] (e.g. `'todo'`), used to route
  /// applied operations to the right [DocumentCodec] / collection.
  final String docType;

  /// Field name within the document for [OpKind.lwwSet], or the collection
  /// namespace for counter/set operations. May be empty for single-value
  /// documents (bare counters/sets).
  final String field;

  /// Which CRDT algorithm this operation belongs to.
  final OpKind kind;

  /// The operation payload; meaning depends on [kind]. Must be JSON
  /// encodable.
  final Object? value;

  /// The Hybrid Logical Clock timestamp this operation was created at.
  final Hlc hlc;

  /// Id of the node (device/install) that produced this operation.
  /// Always equal to `hlc.nodeId`; kept as its own column for convenient
  /// querying/indexing in storage backends.
  final String nodeId;

  const Operation({
    required this.id,
    required this.docId,
    required this.docType,
    required this.field,
    required this.kind,
    required this.value,
    required this.hlc,
    required this.nodeId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'docId': docId,
    'docType': docType,
    'field': field,
    'kind': kind.wireName,
    'value': value,
    'hlc': hlc.toString(),
    'nodeId': nodeId,
  };

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
    id: json['id'] as String,
    docId: json['docId'] as String,
    docType: json['docType'] as String? ?? '',
    field: json['field'] as String? ?? '',
    kind: OpKindCodec.fromWireName(json['kind'] as String),
    value: json['value'],
    hlc: Hlc.parse(json['hlc'] as String),
    nodeId: json['nodeId'] as String,
  );

  Operation copyWith({Object? value, bool clearValue = false}) => Operation(
    id: id,
    docId: docId,
    docType: docType,
    field: field,
    kind: kind,
    value: clearValue ? value : (value ?? this.value),
    hlc: hlc,
    nodeId: nodeId,
  );

  @override
  bool operator ==(Object other) => other is Operation && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Operation(id: $id, docId: $docId, field: $field, kind: ${kind.wireName}, hlc: $hlc)';
}
