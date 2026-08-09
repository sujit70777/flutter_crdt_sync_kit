import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../../crdt/hlc.dart';
import '../../op/op_kind.dart';
import '../../op/operation.dart';
import '../../sync/sync_adapter.dart';

/// A [SyncAdapter] backed by a Supabase Postgres table plus Realtime.
///
/// Expects a table (default name `sync_kit_ops`) with this shape:
///
/// ```sql
/// create table sync_kit_ops (
///   server_seq bigint generated always as identity primary key,
///   id text not null unique,
///   doc_id text not null,
///   doc_type text not null,
///   field text not null,
///   kind text not null,
///   value_json jsonb not null,
///   hlc_millis bigint not null,
///   hlc_counter bigint not null,
///   hlc_node_id text not null,
///   node_id text not null,
///   created_at timestamptz not null default now()
/// );
/// create index sync_kit_ops_doc_id_idx on sync_kit_ops (doc_id);
/// alter table sync_kit_ops enable row level security;
/// -- add RLS policies scoping rows to your app's tenancy model, e.g. a
/// -- doc_id prefix or a separate ACL table joined on doc_id.
/// alter publication supabase_realtime add table sync_kit_ops;
/// ```
///
/// `server_seq` is used as the sync checkpoint/cursor. Pushing is
/// implemented as an upsert on `id`, so retries after a network error that
/// actually succeeded server-side are harmless.
class SupabaseSyncAdapter implements SyncAdapter, RealtimeSyncAdapter {
  @override
  final String id;

  final SupabaseClient client;
  final String table;
  final int pullPageSize;

  RealtimeChannel? _channel;
  StreamController<void>? _changeController;

  SupabaseSyncAdapter({
    this.id = 'supabase',
    required this.client,
    this.table = 'sync_kit_ops',
    this.pullPageSize = 2000,
  });

  @override
  Future<void> push(List<Operation> ops) async {
    if (ops.isEmpty) return;
    await client.from(table).upsert(ops.map(_toRow).toList(), onConflict: 'id');
  }

  @override
  Future<PullResult> pull(String? checkpoint) async {
    final since = checkpoint == null ? 0 : int.parse(checkpoint);
    final rows = await client
        .from(table)
        .select()
        .gt('server_seq', since)
        .order('server_seq')
        .limit(pullPageSize);

    final ops = rows.map(_fromRow).toList();
    if (ops.isEmpty) {
      return const PullResult(ops: [], nextCheckpoint: null);
    }
    final maxSeq = rows.last['server_seq'] as int;
    return PullResult(ops: ops, nextCheckpoint: maxSeq.toString());
  }

  @override
  Stream<void> get remoteChangeSignal {
    var controller = _changeController;
    if (controller != null) return controller.stream;

    controller = StreamController<void>.broadcast(
      onCancel: () {
        final channel = _channel;
        if (channel != null) client.removeChannel(channel);
        _channel = null;
        _changeController = null;
      },
    );
    _changeController = controller;

    _channel = client
        .channel('sync_kit_ops_changes_$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) => controller?.add(null),
        )
        .subscribe();

    return controller.stream;
  }

  Map<String, dynamic> _toRow(Operation op) => {
    'id': op.id,
    'doc_id': op.docId,
    'doc_type': op.docType,
    'field': op.field,
    'kind': op.kind.wireName,
    'value_json': op.value,
    'hlc_millis': op.hlc.millis,
    'hlc_counter': op.hlc.counter,
    'hlc_node_id': op.hlc.nodeId,
    'node_id': op.nodeId,
  };

  Operation _fromRow(Map<String, dynamic> row) {
    // Supabase returns jsonb columns already decoded; guard against
    // clients that hand back a JSON string instead.
    final rawValue = row['value_json'];
    final value = rawValue is String ? jsonDecode(rawValue) : rawValue;
    return Operation(
      id: row['id'] as String,
      docId: row['doc_id'] as String,
      docType: row['doc_type'] as String,
      field: row['field'] as String,
      kind: OpKindCodec.fromWireName(row['kind'] as String),
      value: value,
      hlc: Hlc(
        millis: row['hlc_millis'] as int,
        counter: row['hlc_counter'] as int,
        nodeId: row['hlc_node_id'] as String,
      ),
      nodeId: row['node_id'] as String,
    );
  }
}
