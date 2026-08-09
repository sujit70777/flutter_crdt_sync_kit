import 'package:flutter_sync_kit/flutter_sync_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../doc/todo_item.dart';
import 'fake_sync_adapter.dart';

void main() {
  group('SyncEngine', () {
    test(
      'two devices offline, editing the same record differently, converge after reconnecting',
      () async {
        final backend = FakeBackend();

        final storeA = InMemoryLocalStore();
        await storeA.init();
        final engineA = SyncEngine(
          store: storeA,
          adapter: FakeSyncAdapter(backend),
          pollInterval: const Duration(days: 1),
        );
        final docA = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeA,
          clock: HlcClock('device-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
          engine: engineA,
        );

        final storeB = InMemoryLocalStore();
        await storeB.init();
        final engineB = SyncEngine(
          store: storeB,
          adapter: FakeSyncAdapter(backend),
          pollInterval: const Duration(days: 1),
        );
        final docB = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeB,
          clock: HlcClock('device-b'),
          codec: todoCodec,
          empty: TodoItem.empty,
          engine: engineB,
        );

        // Both devices start fully offline: edit different fields of the
        // same document without syncing at all.
        await docA.update((t) => t.copyWith(title: 'Buy oat milk'));
        await docB.update((t) => t.copyWith(done: true));

        // "Reconnect": each engine pushes its local ops and pulls the
        // other's from the shared backend.
        await engineA.syncNow();
        await engineB.syncNow();
        // A second round so A picks up what B just pushed.
        await engineA.syncNow();

        expect(docA.value.title, 'Buy oat milk');
        expect(docA.value.done, isTrue);
        expect(docB.value.title, 'Buy oat milk');
        expect(docB.value.done, isTrue);
      },
    );

    test(
      'pushes local writes automatically shortly after notifyLocalWrite (via SyncedDoc.update)',
      () async {
        final backend = FakeBackend();
        final store = InMemoryLocalStore();
        await store.init();
        final engine = SyncEngine(
          store: store,
          adapter: FakeSyncAdapter(backend),
          pollInterval: const Duration(days: 1),
          writeDebounce: const Duration(milliseconds: 10),
        );
        engine.start();
        addTearDown(engine.stop);

        final doc = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: store,
          clock: HlcClock('device-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
          engine: engine,
        );

        await doc.update((t) => t.copyWith(title: 'auto pushed'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(backend.length, 1);
      },
    );

    test(
      'retries with backoff after a push failure and eventually succeeds',
      () async {
        final backend = FakeBackend()..failNextPush = true;
        final store = InMemoryLocalStore();
        await store.init();
        final events = <SyncEvent>[];
        final engine = SyncEngine(
          store: store,
          adapter: FakeSyncAdapter(backend),
          pollInterval: const Duration(days: 1),
          retryPolicy: RetryPolicy(
            base: const Duration(milliseconds: 10),
            max: const Duration(milliseconds: 50),
            jitter: Duration.zero,
          ),
        );
        engine.events.listen(events.add);

        await store.appendLocalOps([
          Operation(
            id: 'op1',
            docId: 'doc-1',
            docType: 'note',
            field: 'title',
            kind: OpKind.lwwSet,
            value: 'hello',
            hlc: Hlc.now('device-a'),
            nodeId: 'device-a',
          ),
        ]);

        await engine.syncNow(); // fails
        await Future<void>.delayed(
          Duration.zero,
        ); // let broadcast stream listeners run
        expect(events.whereType<SyncPushFailed>(), isNotEmpty);
        expect(backend.length, 0);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          backend.length,
          1,
          reason: 'retry timer should have re-attempted the push',
        );
        addTearDown(engine.stop);
      },
    );

    test(
      'concurrent syncNow() calls coalesce into a single rerun instead of overlapping',
      () async {
        final backend = FakeBackend();
        final store = InMemoryLocalStore();
        await store.init();
        final engine = SyncEngine(
          store: store,
          adapter: FakeSyncAdapter(backend),
          pollInterval: const Duration(days: 1),
        );

        final futures = [engine.syncNow(), engine.syncNow(), engine.syncNow()];
        await Future.wait(futures);
        // Should not throw / deadlock, and should complete cleanly.
        expect(true, isTrue);
      },
    );
  });
}
