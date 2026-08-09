import 'package:flutter_sync_kit/flutter_sync_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'todo_item.dart';

void main() {
  group('SyncedDoc', () {
    late InMemoryLocalStore store;

    setUp(() async {
      store = InMemoryLocalStore();
      await store.init();
    });

    test('update() writes fields and is reflected in value', () async {
      final doc = await SyncedDoc.open<TodoItem>(
        docId: 'todo_1',
        docType: 'todo',
        store: store,
        clock: HlcClock('node-a'),
        codec: todoCodec,
        empty: TodoItem.empty,
      );

      await doc.update((t) => t.copyWith(title: 'Buy milk'));
      expect(doc.value.title, 'Buy milk');
      expect(doc.value.done, isFalse);

      await doc.update((t) => t.copyWith(done: true));
      expect(doc.value.title, 'Buy milk');
      expect(doc.value.done, isTrue);
    });

    test('update() only writes ops for fields that actually changed', () async {
      final doc = await SyncedDoc.open<TodoItem>(
        docId: 'todo_1',
        docType: 'todo',
        store: store,
        clock: HlcClock('node-a'),
        codec: todoCodec,
        empty: TodoItem.empty,
      );
      await doc.update((t) => t.copyWith(title: 'Buy milk'));
      await doc.update((t) => t.copyWith(title: 'Buy milk')); // no-op change
      final ops = await store.opsForDoc('todo_1');
      expect(ops.length, 1);
    });

    test('stream emits the new value after each update', () async {
      final doc = await SyncedDoc.open<TodoItem>(
        docId: 'todo_1',
        docType: 'todo',
        store: store,
        clock: HlcClock('node-a'),
        codec: todoCodec,
        empty: TodoItem.empty,
      );
      final values = <TodoItem>[];
      final sub = doc.stream.listen(values.add);

      await doc.update((t) => t.copyWith(title: 'a'));
      await doc.update((t) => t.copyWith(done: true));
      await Future<void>.delayed(Duration.zero);

      expect(values.map((v) => v.title), ['a', 'a']);
      expect(values.map((v) => v.done), [false, true]);
      await sub.cancel();
    });

    test(
      'opening the same docId twice from the same store reconstructs the same value',
      () async {
        final doc1 = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: store,
          clock: HlcClock('node-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );
        await doc1.update((t) => t.copyWith(title: 'Buy milk', done: true));

        final doc2 = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: store,
          clock: HlcClock('node-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        expect(doc2.value.title, 'Buy milk');
        expect(doc2.value.done, isTrue);
      },
    );

    test(
      'a second live SyncedDoc for the same docId observes updates from the first',
      () async {
        final clock = HlcClock('node-a');
        final doc1 = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: store,
          clock: clock,
          codec: todoCodec,
          empty: TodoItem.empty,
        );
        final doc2 = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: store,
          clock: clock,
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        final future = doc2.stream.first;
        await doc1.update((t) => t.copyWith(title: 'from doc1'));
        final observed = await future;
        expect(observed.title, 'from doc1');
        expect(doc2.value.title, 'from doc1');
      },
    );

    test(
      'editing different fields concurrently on two replicas merges both edits',
      () async {
        // Simulate two devices editing the same document offline: each has
        // its own LocalStore and clock, then their ops are merged into one.
        final storeA = InMemoryLocalStore()..init();
        final storeB = InMemoryLocalStore()..init();

        final docA = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeA,
          clock: HlcClock('device-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );
        final docB = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeB,
          clock: HlcClock('device-b'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        await docA.update(
          (t) => t.copyWith(title: 'Buy oat milk'),
        ); // A edits title
        await docB.update(
          (t) => t.copyWith(done: true),
        ); // B edits done, concurrently

        // "Reconnect": exchange each device's ops with a fresh merge store,
        // like a SyncEngine would after push+pull on both sides.
        final merged = InMemoryLocalStore()..init();
        await merged.ingestRemoteOps('a', await storeA.opsForDoc('todo_1'));
        await merged.ingestRemoteOps('b', await storeB.opsForDoc('todo_1'));

        final result = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: merged,
          clock: HlcClock('observer'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        expect(result.value.title, 'Buy oat milk');
        expect(result.value.done, isTrue);
      },
    );

    test(
      'concurrent edits to the SAME field converge to the same winner on both replicas',
      () async {
        final storeA = InMemoryLocalStore()..init();
        final storeB = InMemoryLocalStore()..init();

        final docA = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeA,
          clock: HlcClock('device-a'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );
        final docB = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: storeB,
          clock: HlcClock('device-b'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        await docA.update((t) => t.copyWith(title: 'from A'));
        await docB.update((t) => t.copyWith(title: 'from B'));

        final opsA = await storeA.opsForDoc('todo_1');
        final opsB = await storeB.opsForDoc('todo_1');

        // Merge in one order...
        final mergedAB = InMemoryLocalStore()..init();
        await mergedAB.ingestRemoteOps('a', opsA);
        await mergedAB.ingestRemoteOps('b', opsB);
        final resultAB = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: mergedAB,
          clock: HlcClock('observer'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        // ...and the opposite order.
        final mergedBA = InMemoryLocalStore()..init();
        await mergedBA.ingestRemoteOps('b', opsB);
        await mergedBA.ingestRemoteOps('a', opsA);
        final resultBA = await SyncedDoc.open<TodoItem>(
          docId: 'todo_1',
          docType: 'todo',
          store: mergedBA,
          clock: HlcClock('observer'),
          codec: todoCodec,
          empty: TodoItem.empty,
        );

        expect(resultAB.value.title, resultBA.value.title);
      },
    );
  });
}
