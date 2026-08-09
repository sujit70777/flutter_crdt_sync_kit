import 'package:flutter_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_sync_kit/src/op/op_kind.dart';
import 'package:flutter_sync_kit/src/op/operation.dart';
import 'package:flutter_sync_kit/src/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

Operation _op(String id, {String docId = 'doc-1', int millis = 100}) =>
    Operation(
      id: id,
      docId: docId,
      docType: 'note',
      field: 'title',
      kind: OpKind.lwwSet,
      value: 'value-$id',
      hlc: Hlc(millis: millis, counter: 0, nodeId: 'node-a'),
      nodeId: 'node-a',
    );

/// A shared behavioral contract every [LocalStore] implementation must
/// satisfy, run against both [InMemoryLocalStore] and [DriftLocalStore] to
/// keep them interchangeable.
void runLocalStoreContractTests(
  String name,
  Future<LocalStore> Function() create,
) {
  group('LocalStore contract ($name)', () {
    late LocalStore store;

    setUp(() async {
      store = await create();
      await store.init();
    });

    tearDown(() async {
      await store.close();
    });

    test('appendLocalOps makes ops retrievable via opsForDoc', () async {
      await store.appendLocalOps([_op('op1'), _op('op2')]);
      final ops = await store.opsForDoc('doc-1');
      expect(ops.map((o) => o.id).toSet(), {'op1', 'op2'});
    });

    test('opsForDoc only returns ops for that doc', () async {
      await store.appendLocalOps([
        _op('op1', docId: 'doc-1'),
        _op('op2', docId: 'doc-2'),
      ]);
      final ops = await store.opsForDoc('doc-1');
      expect(ops.map((o) => o.id).toList(), ['op1']);
    });

    test('duplicate local op ids are not stored twice', () async {
      final op = _op('op1');
      await store.appendLocalOps([op]);
      await store.appendLocalOps([op]);
      final ops = await store.opsForDoc('doc-1');
      expect(ops.length, 1);
    });

    test('pendingOps returns everything before any push is marked', () async {
      await store.appendLocalOps([_op('op1'), _op('op2')]);
      final pending = await store.pendingOps('supabase');
      expect(pending.map((o) => o.id).toSet(), {'op1', 'op2'});
    });

    test(
      'markPushed excludes ops from future pendingOps calls for that adapter',
      () async {
        await store.appendLocalOps([_op('op1'), _op('op2')]);
        await store.markPushed('supabase', ['op1']);
        final pending = await store.pendingOps('supabase');
        expect(pending.map((o) => o.id).toList(), ['op2']);
      },
    );

    test('push status is tracked independently per adapter', () async {
      await store.appendLocalOps([_op('op1')]);
      await store.markPushed('supabase', ['op1']);
      final pendingForRest = await store.pendingOps('rest');
      expect(pendingForRest.map((o) => o.id).toList(), ['op1']);
      final pendingForSupabase = await store.pendingOps('supabase');
      expect(pendingForSupabase, isEmpty);
    });

    test(
      'ingestRemoteOps stores new ops and returns only the newly-seen ones',
      () async {
        final local = _op('local1');
        await store.appendLocalOps([local]);

        final newlyIngested = await store.ingestRemoteOps('supabase', [
          local,
          _op('remote1'),
        ]);
        expect(newlyIngested.map((o) => o.id).toList(), ['remote1']);

        final all = await store.opsForDoc('doc-1');
        expect(all.map((o) => o.id).toSet(), {'local1', 'remote1'});
      },
    );

    test(
      'ops ingested from a remote adapter are marked pushed to that same adapter',
      () async {
        await store.ingestRemoteOps('supabase', [_op('remote1')]);
        final pending = await store.pendingOps('supabase');
        expect(
          pending,
          isEmpty,
          reason:
              'ops that came from an adapter should not be echoed back to it',
        );
      },
    );

    test('checkpoints round-trip and default to null', () async {
      expect(await store.getCheckpoint('supabase'), isNull);
      await store.setCheckpoint('supabase', 'cursor-42');
      expect(await store.getCheckpoint('supabase'), 'cursor-42');
      await store.setCheckpoint('supabase', 'cursor-99');
      expect(await store.getCheckpoint('supabase'), 'cursor-99');
    });

    test(
      'changes stream emits on local append with fromRemote=false',
      () async {
        final future = store.changes.first;
        await store.appendLocalOps([_op('op1')]);
        final batch = await future;
        expect(batch.fromRemote, isFalse);
        expect(batch.docIds, {'doc-1'});
      },
    );

    test(
      'changes stream emits on remote ingest with fromRemote=true',
      () async {
        final future = store.changes.first;
        await store.ingestRemoteOps('supabase', [_op('op1')]);
        final batch = await future;
        expect(batch.fromRemote, isTrue);
        expect(batch.docIds, {'doc-1'});
      },
    );

    test('allOps returns every operation across all docs', () async {
      await store.appendLocalOps([
        _op('op1', docId: 'doc-1'),
        _op('op2', docId: 'doc-2'),
      ]);
      final all = await store.allOps();
      expect(all.map((o) => o.id).toSet(), {'op1', 'op2'});
    });

    test('operation value survives the storage round-trip exactly', () async {
      final op = Operation(
        id: 'complex1',
        docId: 'doc-1',
        docType: 'note',
        field: 'meta',
        kind: OpKind.lwwSet,
        value: {
          'nested': ['a', 1, true, null],
          'n': 3.14,
        },
        hlc: Hlc(millis: 500, counter: 2, nodeId: 'node-z'),
        nodeId: 'node-z',
      );
      await store.appendLocalOps([op]);
      final roundTripped = (await store.opsForDoc('doc-1')).single;
      expect(roundTripped.value, op.value);
      expect(roundTripped.hlc, op.hlc);
    });
  });
}
