// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $OpsTable extends Ops with TableInfo<$OpsTable, OpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMillisMeta = const VerificationMeta(
    'hlcMillis',
  );
  @override
  late final GeneratedColumn<int> hlcMillis = GeneratedColumn<int>(
    'hlc_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcCounterMeta = const VerificationMeta(
    'hlcCounter',
  );
  @override
  late final GeneratedColumn<int> hlcCounter = GeneratedColumn<int>(
    'hlc_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcNodeIdMeta = const VerificationMeta(
    'hlcNodeId',
  );
  @override
  late final GeneratedColumn<String> hlcNodeId = GeneratedColumn<String>(
    'hlc_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    docId,
    docType,
    field,
    kind,
    valueJson,
    hlcMillis,
    hlcCounter,
    hlcNodeId,
    nodeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('hlc_millis')) {
      context.handle(
        _hlcMillisMeta,
        hlcMillis.isAcceptableOrUnknown(data['hlc_millis']!, _hlcMillisMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMillisMeta);
    }
    if (data.containsKey('hlc_counter')) {
      context.handle(
        _hlcCounterMeta,
        hlcCounter.isAcceptableOrUnknown(data['hlc_counter']!, _hlcCounterMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcCounterMeta);
    }
    if (data.containsKey('hlc_node_id')) {
      context.handle(
        _hlcNodeIdMeta,
        hlcNodeId.isAcceptableOrUnknown(data['hlc_node_id']!, _hlcNodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcNodeIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      hlcMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_millis'],
      )!,
      hlcCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_counter'],
      )!,
      hlcNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc_node_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
    );
  }

  @override
  $OpsTable createAlias(String alias) {
    return $OpsTable(attachedDatabase, alias);
  }
}

class OpRow extends DataClass implements Insertable<OpRow> {
  /// Auto-incrementing insertion order; not part of the CRDT identity of a
  /// row, just a convenient replay/debug ordering.
  final int seq;
  final String id;
  final String docId;
  final String docType;
  final String field;
  final String kind;
  final String valueJson;
  final int hlcMillis;
  final int hlcCounter;
  final String hlcNodeId;
  final String nodeId;
  const OpRow({
    required this.seq,
    required this.id,
    required this.docId,
    required this.docType,
    required this.field,
    required this.kind,
    required this.valueJson,
    required this.hlcMillis,
    required this.hlcCounter,
    required this.hlcNodeId,
    required this.nodeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    map['doc_id'] = Variable<String>(docId);
    map['doc_type'] = Variable<String>(docType);
    map['field'] = Variable<String>(field);
    map['kind'] = Variable<String>(kind);
    map['value_json'] = Variable<String>(valueJson);
    map['hlc_millis'] = Variable<int>(hlcMillis);
    map['hlc_counter'] = Variable<int>(hlcCounter);
    map['hlc_node_id'] = Variable<String>(hlcNodeId);
    map['node_id'] = Variable<String>(nodeId);
    return map;
  }

  OpsCompanion toCompanion(bool nullToAbsent) {
    return OpsCompanion(
      seq: Value(seq),
      id: Value(id),
      docId: Value(docId),
      docType: Value(docType),
      field: Value(field),
      kind: Value(kind),
      valueJson: Value(valueJson),
      hlcMillis: Value(hlcMillis),
      hlcCounter: Value(hlcCounter),
      hlcNodeId: Value(hlcNodeId),
      nodeId: Value(nodeId),
    );
  }

  factory OpRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpRow(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      docId: serializer.fromJson<String>(json['docId']),
      docType: serializer.fromJson<String>(json['docType']),
      field: serializer.fromJson<String>(json['field']),
      kind: serializer.fromJson<String>(json['kind']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      hlcMillis: serializer.fromJson<int>(json['hlcMillis']),
      hlcCounter: serializer.fromJson<int>(json['hlcCounter']),
      hlcNodeId: serializer.fromJson<String>(json['hlcNodeId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'docId': serializer.toJson<String>(docId),
      'docType': serializer.toJson<String>(docType),
      'field': serializer.toJson<String>(field),
      'kind': serializer.toJson<String>(kind),
      'valueJson': serializer.toJson<String>(valueJson),
      'hlcMillis': serializer.toJson<int>(hlcMillis),
      'hlcCounter': serializer.toJson<int>(hlcCounter),
      'hlcNodeId': serializer.toJson<String>(hlcNodeId),
      'nodeId': serializer.toJson<String>(nodeId),
    };
  }

  OpRow copyWith({
    int? seq,
    String? id,
    String? docId,
    String? docType,
    String? field,
    String? kind,
    String? valueJson,
    int? hlcMillis,
    int? hlcCounter,
    String? hlcNodeId,
    String? nodeId,
  }) => OpRow(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    docId: docId ?? this.docId,
    docType: docType ?? this.docType,
    field: field ?? this.field,
    kind: kind ?? this.kind,
    valueJson: valueJson ?? this.valueJson,
    hlcMillis: hlcMillis ?? this.hlcMillis,
    hlcCounter: hlcCounter ?? this.hlcCounter,
    hlcNodeId: hlcNodeId ?? this.hlcNodeId,
    nodeId: nodeId ?? this.nodeId,
  );
  OpRow copyWithCompanion(OpsCompanion data) {
    return OpRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      docId: data.docId.present ? data.docId.value : this.docId,
      docType: data.docType.present ? data.docType.value : this.docType,
      field: data.field.present ? data.field.value : this.field,
      kind: data.kind.present ? data.kind.value : this.kind,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      hlcMillis: data.hlcMillis.present ? data.hlcMillis.value : this.hlcMillis,
      hlcCounter: data.hlcCounter.present
          ? data.hlcCounter.value
          : this.hlcCounter,
      hlcNodeId: data.hlcNodeId.present ? data.hlcNodeId.value : this.hlcNodeId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpRow(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('docType: $docType, ')
          ..write('field: $field, ')
          ..write('kind: $kind, ')
          ..write('valueJson: $valueJson, ')
          ..write('hlcMillis: $hlcMillis, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('hlcNodeId: $hlcNodeId, ')
          ..write('nodeId: $nodeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    docId,
    docType,
    field,
    kind,
    valueJson,
    hlcMillis,
    hlcCounter,
    hlcNodeId,
    nodeId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpRow &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.docId == this.docId &&
          other.docType == this.docType &&
          other.field == this.field &&
          other.kind == this.kind &&
          other.valueJson == this.valueJson &&
          other.hlcMillis == this.hlcMillis &&
          other.hlcCounter == this.hlcCounter &&
          other.hlcNodeId == this.hlcNodeId &&
          other.nodeId == this.nodeId);
}

class OpsCompanion extends UpdateCompanion<OpRow> {
  final Value<int> seq;
  final Value<String> id;
  final Value<String> docId;
  final Value<String> docType;
  final Value<String> field;
  final Value<String> kind;
  final Value<String> valueJson;
  final Value<int> hlcMillis;
  final Value<int> hlcCounter;
  final Value<String> hlcNodeId;
  final Value<String> nodeId;
  const OpsCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.docId = const Value.absent(),
    this.docType = const Value.absent(),
    this.field = const Value.absent(),
    this.kind = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.hlcMillis = const Value.absent(),
    this.hlcCounter = const Value.absent(),
    this.hlcNodeId = const Value.absent(),
    this.nodeId = const Value.absent(),
  });
  OpsCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    required String docId,
    required String docType,
    required String field,
    required String kind,
    required String valueJson,
    required int hlcMillis,
    required int hlcCounter,
    required String hlcNodeId,
    required String nodeId,
  }) : id = Value(id),
       docId = Value(docId),
       docType = Value(docType),
       field = Value(field),
       kind = Value(kind),
       valueJson = Value(valueJson),
       hlcMillis = Value(hlcMillis),
       hlcCounter = Value(hlcCounter),
       hlcNodeId = Value(hlcNodeId),
       nodeId = Value(nodeId);
  static Insertable<OpRow> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<String>? docId,
    Expression<String>? docType,
    Expression<String>? field,
    Expression<String>? kind,
    Expression<String>? valueJson,
    Expression<int>? hlcMillis,
    Expression<int>? hlcCounter,
    Expression<String>? hlcNodeId,
    Expression<String>? nodeId,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (docId != null) 'doc_id': docId,
      if (docType != null) 'doc_type': docType,
      if (field != null) 'field': field,
      if (kind != null) 'kind': kind,
      if (valueJson != null) 'value_json': valueJson,
      if (hlcMillis != null) 'hlc_millis': hlcMillis,
      if (hlcCounter != null) 'hlc_counter': hlcCounter,
      if (hlcNodeId != null) 'hlc_node_id': hlcNodeId,
      if (nodeId != null) 'node_id': nodeId,
    });
  }

  OpsCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<String>? docId,
    Value<String>? docType,
    Value<String>? field,
    Value<String>? kind,
    Value<String>? valueJson,
    Value<int>? hlcMillis,
    Value<int>? hlcCounter,
    Value<String>? hlcNodeId,
    Value<String>? nodeId,
  }) {
    return OpsCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      docId: docId ?? this.docId,
      docType: docType ?? this.docType,
      field: field ?? this.field,
      kind: kind ?? this.kind,
      valueJson: valueJson ?? this.valueJson,
      hlcMillis: hlcMillis ?? this.hlcMillis,
      hlcCounter: hlcCounter ?? this.hlcCounter,
      hlcNodeId: hlcNodeId ?? this.hlcNodeId,
      nodeId: nodeId ?? this.nodeId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (hlcMillis.present) {
      map['hlc_millis'] = Variable<int>(hlcMillis.value);
    }
    if (hlcCounter.present) {
      map['hlc_counter'] = Variable<int>(hlcCounter.value);
    }
    if (hlcNodeId.present) {
      map['hlc_node_id'] = Variable<String>(hlcNodeId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpsCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('docType: $docType, ')
          ..write('field: $field, ')
          ..write('kind: $kind, ')
          ..write('valueJson: $valueJson, ')
          ..write('hlcMillis: $hlcMillis, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('hlcNodeId: $hlcNodeId, ')
          ..write('nodeId: $nodeId')
          ..write(')'))
        .toString();
  }
}

class $PushStatusTable extends PushStatus
    with TableInfo<$PushStatusTable, PushStatusRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PushStatusTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adapterIdMeta = const VerificationMeta(
    'adapterId',
  );
  @override
  late final GeneratedColumn<String> adapterId = GeneratedColumn<String>(
    'adapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [opId, adapterId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'push_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<PushStatusRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('adapter_id')) {
      context.handle(
        _adapterIdMeta,
        adapterId.isAcceptableOrUnknown(data['adapter_id']!, _adapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_adapterIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId, adapterId};
  @override
  PushStatusRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PushStatusRow(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      adapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adapter_id'],
      )!,
    );
  }

  @override
  $PushStatusTable createAlias(String alias) {
    return $PushStatusTable(attachedDatabase, alias);
  }
}

class PushStatusRow extends DataClass implements Insertable<PushStatusRow> {
  final String opId;
  final String adapterId;
  const PushStatusRow({required this.opId, required this.adapterId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['adapter_id'] = Variable<String>(adapterId);
    return map;
  }

  PushStatusCompanion toCompanion(bool nullToAbsent) {
    return PushStatusCompanion(opId: Value(opId), adapterId: Value(adapterId));
  }

  factory PushStatusRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PushStatusRow(
      opId: serializer.fromJson<String>(json['opId']),
      adapterId: serializer.fromJson<String>(json['adapterId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'adapterId': serializer.toJson<String>(adapterId),
    };
  }

  PushStatusRow copyWith({String? opId, String? adapterId}) => PushStatusRow(
    opId: opId ?? this.opId,
    adapterId: adapterId ?? this.adapterId,
  );
  PushStatusRow copyWithCompanion(PushStatusCompanion data) {
    return PushStatusRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      adapterId: data.adapterId.present ? data.adapterId.value : this.adapterId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PushStatusRow(')
          ..write('opId: $opId, ')
          ..write('adapterId: $adapterId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(opId, adapterId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PushStatusRow &&
          other.opId == this.opId &&
          other.adapterId == this.adapterId);
}

class PushStatusCompanion extends UpdateCompanion<PushStatusRow> {
  final Value<String> opId;
  final Value<String> adapterId;
  final Value<int> rowid;
  const PushStatusCompanion({
    this.opId = const Value.absent(),
    this.adapterId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PushStatusCompanion.insert({
    required String opId,
    required String adapterId,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       adapterId = Value(adapterId);
  static Insertable<PushStatusRow> custom({
    Expression<String>? opId,
    Expression<String>? adapterId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (adapterId != null) 'adapter_id': adapterId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PushStatusCompanion copyWith({
    Value<String>? opId,
    Value<String>? adapterId,
    Value<int>? rowid,
  }) {
    return PushStatusCompanion(
      opId: opId ?? this.opId,
      adapterId: adapterId ?? this.adapterId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (adapterId.present) {
      map['adapter_id'] = Variable<String>(adapterId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PushStatusCompanion(')
          ..write('opId: $opId, ')
          ..write('adapterId: $adapterId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckpointsTable extends Checkpoints
    with TableInfo<$CheckpointsTable, CheckpointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _adapterIdMeta = const VerificationMeta(
    'adapterId',
  );
  @override
  late final GeneratedColumn<String> adapterId = GeneratedColumn<String>(
    'adapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkpointMeta = const VerificationMeta(
    'checkpoint',
  );
  @override
  late final GeneratedColumn<String> checkpoint = GeneratedColumn<String>(
    'checkpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [adapterId, checkpoint];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckpointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('adapter_id')) {
      context.handle(
        _adapterIdMeta,
        adapterId.isAcceptableOrUnknown(data['adapter_id']!, _adapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_adapterIdMeta);
    }
    if (data.containsKey('checkpoint')) {
      context.handle(
        _checkpointMeta,
        checkpoint.isAcceptableOrUnknown(data['checkpoint']!, _checkpointMeta),
      );
    } else if (isInserting) {
      context.missing(_checkpointMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {adapterId};
  @override
  CheckpointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckpointRow(
      adapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adapter_id'],
      )!,
      checkpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkpoint'],
      )!,
    );
  }

  @override
  $CheckpointsTable createAlias(String alias) {
    return $CheckpointsTable(attachedDatabase, alias);
  }
}

class CheckpointRow extends DataClass implements Insertable<CheckpointRow> {
  final String adapterId;
  final String checkpoint;
  const CheckpointRow({required this.adapterId, required this.checkpoint});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['adapter_id'] = Variable<String>(adapterId);
    map['checkpoint'] = Variable<String>(checkpoint);
    return map;
  }

  CheckpointsCompanion toCompanion(bool nullToAbsent) {
    return CheckpointsCompanion(
      adapterId: Value(adapterId),
      checkpoint: Value(checkpoint),
    );
  }

  factory CheckpointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckpointRow(
      adapterId: serializer.fromJson<String>(json['adapterId']),
      checkpoint: serializer.fromJson<String>(json['checkpoint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'adapterId': serializer.toJson<String>(adapterId),
      'checkpoint': serializer.toJson<String>(checkpoint),
    };
  }

  CheckpointRow copyWith({String? adapterId, String? checkpoint}) =>
      CheckpointRow(
        adapterId: adapterId ?? this.adapterId,
        checkpoint: checkpoint ?? this.checkpoint,
      );
  CheckpointRow copyWithCompanion(CheckpointsCompanion data) {
    return CheckpointRow(
      adapterId: data.adapterId.present ? data.adapterId.value : this.adapterId,
      checkpoint: data.checkpoint.present
          ? data.checkpoint.value
          : this.checkpoint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointRow(')
          ..write('adapterId: $adapterId, ')
          ..write('checkpoint: $checkpoint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(adapterId, checkpoint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckpointRow &&
          other.adapterId == this.adapterId &&
          other.checkpoint == this.checkpoint);
}

class CheckpointsCompanion extends UpdateCompanion<CheckpointRow> {
  final Value<String> adapterId;
  final Value<String> checkpoint;
  final Value<int> rowid;
  const CheckpointsCompanion({
    this.adapterId = const Value.absent(),
    this.checkpoint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckpointsCompanion.insert({
    required String adapterId,
    required String checkpoint,
    this.rowid = const Value.absent(),
  }) : adapterId = Value(adapterId),
       checkpoint = Value(checkpoint);
  static Insertable<CheckpointRow> custom({
    Expression<String>? adapterId,
    Expression<String>? checkpoint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (adapterId != null) 'adapter_id': adapterId,
      if (checkpoint != null) 'checkpoint': checkpoint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckpointsCompanion copyWith({
    Value<String>? adapterId,
    Value<String>? checkpoint,
    Value<int>? rowid,
  }) {
    return CheckpointsCompanion(
      adapterId: adapterId ?? this.adapterId,
      checkpoint: checkpoint ?? this.checkpoint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (adapterId.present) {
      map['adapter_id'] = Variable<String>(adapterId.value);
    }
    if (checkpoint.present) {
      map['checkpoint'] = Variable<String>(checkpoint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointsCompanion(')
          ..write('adapterId: $adapterId, ')
          ..write('checkpoint: $checkpoint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncKitDatabase extends GeneratedDatabase {
  _$SyncKitDatabase(QueryExecutor e) : super(e);
  $SyncKitDatabaseManager get managers => $SyncKitDatabaseManager(this);
  late final $OpsTable ops = $OpsTable(this);
  late final $PushStatusTable pushStatus = $PushStatusTable(this);
  late final $CheckpointsTable checkpoints = $CheckpointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ops,
    pushStatus,
    checkpoints,
  ];
}

typedef $$OpsTableCreateCompanionBuilder =
    OpsCompanion Function({
      Value<int> seq,
      required String id,
      required String docId,
      required String docType,
      required String field,
      required String kind,
      required String valueJson,
      required int hlcMillis,
      required int hlcCounter,
      required String hlcNodeId,
      required String nodeId,
    });
typedef $$OpsTableUpdateCompanionBuilder =
    OpsCompanion Function({
      Value<int> seq,
      Value<String> id,
      Value<String> docId,
      Value<String> docType,
      Value<String> field,
      Value<String> kind,
      Value<String> valueJson,
      Value<int> hlcMillis,
      Value<int> hlcCounter,
      Value<String> hlcNodeId,
      Value<String> nodeId,
    });

class $$OpsTableFilterComposer extends Composer<_$SyncKitDatabase, $OpsTable> {
  $$OpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcMillis => $composableBuilder(
    column: $table.hlcMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlcNodeId => $composableBuilder(
    column: $table.hlcNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpsTableOrderingComposer
    extends Composer<_$SyncKitDatabase, $OpsTable> {
  $$OpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcMillis => $composableBuilder(
    column: $table.hlcMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlcNodeId => $composableBuilder(
    column: $table.hlcNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpsTableAnnotationComposer
    extends Composer<_$SyncKitDatabase, $OpsTable> {
  $$OpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get docId =>
      $composableBuilder(column: $table.docId, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get hlcMillis =>
      $composableBuilder(column: $table.hlcMillis, builder: (column) => column);

  GeneratedColumn<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlcNodeId =>
      $composableBuilder(column: $table.hlcNodeId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);
}

class $$OpsTableTableManager
    extends
        RootTableManager<
          _$SyncKitDatabase,
          $OpsTable,
          OpRow,
          $$OpsTableFilterComposer,
          $$OpsTableOrderingComposer,
          $$OpsTableAnnotationComposer,
          $$OpsTableCreateCompanionBuilder,
          $$OpsTableUpdateCompanionBuilder,
          (OpRow, BaseReferences<_$SyncKitDatabase, $OpsTable, OpRow>),
          OpRow,
          PrefetchHooks Function()
        > {
  $$OpsTableTableManager(_$SyncKitDatabase db, $OpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<String> docType = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> hlcMillis = const Value.absent(),
                Value<int> hlcCounter = const Value.absent(),
                Value<String> hlcNodeId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
              }) => OpsCompanion(
                seq: seq,
                id: id,
                docId: docId,
                docType: docType,
                field: field,
                kind: kind,
                valueJson: valueJson,
                hlcMillis: hlcMillis,
                hlcCounter: hlcCounter,
                hlcNodeId: hlcNodeId,
                nodeId: nodeId,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String id,
                required String docId,
                required String docType,
                required String field,
                required String kind,
                required String valueJson,
                required int hlcMillis,
                required int hlcCounter,
                required String hlcNodeId,
                required String nodeId,
              }) => OpsCompanion.insert(
                seq: seq,
                id: id,
                docId: docId,
                docType: docType,
                field: field,
                kind: kind,
                valueJson: valueJson,
                hlcMillis: hlcMillis,
                hlcCounter: hlcCounter,
                hlcNodeId: hlcNodeId,
                nodeId: nodeId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncKitDatabase,
      $OpsTable,
      OpRow,
      $$OpsTableFilterComposer,
      $$OpsTableOrderingComposer,
      $$OpsTableAnnotationComposer,
      $$OpsTableCreateCompanionBuilder,
      $$OpsTableUpdateCompanionBuilder,
      (OpRow, BaseReferences<_$SyncKitDatabase, $OpsTable, OpRow>),
      OpRow,
      PrefetchHooks Function()
    >;
typedef $$PushStatusTableCreateCompanionBuilder =
    PushStatusCompanion Function({
      required String opId,
      required String adapterId,
      Value<int> rowid,
    });
typedef $$PushStatusTableUpdateCompanionBuilder =
    PushStatusCompanion Function({
      Value<String> opId,
      Value<String> adapterId,
      Value<int> rowid,
    });

class $$PushStatusTableFilterComposer
    extends Composer<_$SyncKitDatabase, $PushStatusTable> {
  $$PushStatusTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PushStatusTableOrderingComposer
    extends Composer<_$SyncKitDatabase, $PushStatusTable> {
  $$PushStatusTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PushStatusTableAnnotationComposer
    extends Composer<_$SyncKitDatabase, $PushStatusTable> {
  $$PushStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get adapterId =>
      $composableBuilder(column: $table.adapterId, builder: (column) => column);
}

class $$PushStatusTableTableManager
    extends
        RootTableManager<
          _$SyncKitDatabase,
          $PushStatusTable,
          PushStatusRow,
          $$PushStatusTableFilterComposer,
          $$PushStatusTableOrderingComposer,
          $$PushStatusTableAnnotationComposer,
          $$PushStatusTableCreateCompanionBuilder,
          $$PushStatusTableUpdateCompanionBuilder,
          (
            PushStatusRow,
            BaseReferences<_$SyncKitDatabase, $PushStatusTable, PushStatusRow>,
          ),
          PushStatusRow,
          PrefetchHooks Function()
        > {
  $$PushStatusTableTableManager(_$SyncKitDatabase db, $PushStatusTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PushStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PushStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PushStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> adapterId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PushStatusCompanion(
                opId: opId,
                adapterId: adapterId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String adapterId,
                Value<int> rowid = const Value.absent(),
              }) => PushStatusCompanion.insert(
                opId: opId,
                adapterId: adapterId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PushStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncKitDatabase,
      $PushStatusTable,
      PushStatusRow,
      $$PushStatusTableFilterComposer,
      $$PushStatusTableOrderingComposer,
      $$PushStatusTableAnnotationComposer,
      $$PushStatusTableCreateCompanionBuilder,
      $$PushStatusTableUpdateCompanionBuilder,
      (
        PushStatusRow,
        BaseReferences<_$SyncKitDatabase, $PushStatusTable, PushStatusRow>,
      ),
      PushStatusRow,
      PrefetchHooks Function()
    >;
typedef $$CheckpointsTableCreateCompanionBuilder =
    CheckpointsCompanion Function({
      required String adapterId,
      required String checkpoint,
      Value<int> rowid,
    });
typedef $$CheckpointsTableUpdateCompanionBuilder =
    CheckpointsCompanion Function({
      Value<String> adapterId,
      Value<String> checkpoint,
      Value<int> rowid,
    });

class $$CheckpointsTableFilterComposer
    extends Composer<_$SyncKitDatabase, $CheckpointsTable> {
  $$CheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkpoint => $composableBuilder(
    column: $table.checkpoint,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckpointsTableOrderingComposer
    extends Composer<_$SyncKitDatabase, $CheckpointsTable> {
  $$CheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkpoint => $composableBuilder(
    column: $table.checkpoint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckpointsTableAnnotationComposer
    extends Composer<_$SyncKitDatabase, $CheckpointsTable> {
  $$CheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get adapterId =>
      $composableBuilder(column: $table.adapterId, builder: (column) => column);

  GeneratedColumn<String> get checkpoint => $composableBuilder(
    column: $table.checkpoint,
    builder: (column) => column,
  );
}

class $$CheckpointsTableTableManager
    extends
        RootTableManager<
          _$SyncKitDatabase,
          $CheckpointsTable,
          CheckpointRow,
          $$CheckpointsTableFilterComposer,
          $$CheckpointsTableOrderingComposer,
          $$CheckpointsTableAnnotationComposer,
          $$CheckpointsTableCreateCompanionBuilder,
          $$CheckpointsTableUpdateCompanionBuilder,
          (
            CheckpointRow,
            BaseReferences<_$SyncKitDatabase, $CheckpointsTable, CheckpointRow>,
          ),
          CheckpointRow,
          PrefetchHooks Function()
        > {
  $$CheckpointsTableTableManager(_$SyncKitDatabase db, $CheckpointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> adapterId = const Value.absent(),
                Value<String> checkpoint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckpointsCompanion(
                adapterId: adapterId,
                checkpoint: checkpoint,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String adapterId,
                required String checkpoint,
                Value<int> rowid = const Value.absent(),
              }) => CheckpointsCompanion.insert(
                adapterId: adapterId,
                checkpoint: checkpoint,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncKitDatabase,
      $CheckpointsTable,
      CheckpointRow,
      $$CheckpointsTableFilterComposer,
      $$CheckpointsTableOrderingComposer,
      $$CheckpointsTableAnnotationComposer,
      $$CheckpointsTableCreateCompanionBuilder,
      $$CheckpointsTableUpdateCompanionBuilder,
      (
        CheckpointRow,
        BaseReferences<_$SyncKitDatabase, $CheckpointsTable, CheckpointRow>,
      ),
      CheckpointRow,
      PrefetchHooks Function()
    >;

class $SyncKitDatabaseManager {
  final _$SyncKitDatabase _db;
  $SyncKitDatabaseManager(this._db);
  $$OpsTableTableManager get ops => $$OpsTableTableManager(_db, _db.ops);
  $$PushStatusTableTableManager get pushStatus =>
      $$PushStatusTableTableManager(_db, _db.pushStatus);
  $$CheckpointsTableTableManager get checkpoints =>
      $$CheckpointsTableTableManager(_db, _db.checkpoints);
}
