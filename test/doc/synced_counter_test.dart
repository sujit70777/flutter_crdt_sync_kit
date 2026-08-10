import 'package:flutter_crdt_sync_kit/flutter_crdt_sync_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncedCounter', () {
    test('increment/decrement update value and stream', () async {
      final store = InMemoryLocalStore();
      await store.init();
      final counter = await SyncedCounter.open(
        docId: 'likes_1',
        store: store,
        clock: HlcClock('node-a'),
      );

      final values = <num>[];
      final sub = counter.stream.listen(values.add);

      await counter.increment();
      await counter.increment(4);
      await counter.decrement(2);
      await Future<void>.delayed(Duration.zero);

      expect(counter.value, 3);
      expect(values, [1, 5, 3]);
      await sub.cancel();
    });

    test('rejects negative deltas', () async {
      final store = InMemoryLocalStore();
      await store.init();
      final counter = await SyncedCounter.open(
        docId: 'c1',
        store: store,
        clock: HlcClock('a'),
      );
      expect(() => counter.increment(-1), throwsArgumentError);
    });

    test(
      'two devices incrementing offline converge to the combined total after merge',
      () async {
        final storeA = InMemoryLocalStore()..init();
        final storeB = InMemoryLocalStore()..init();

        final counterA = await SyncedCounter.open(
          docId: 'likes_1',
          store: storeA,
          clock: HlcClock('device-a'),
        );
        final counterB = await SyncedCounter.open(
          docId: 'likes_1',
          store: storeB,
          clock: HlcClock('device-b'),
        );

        await counterA.increment(3);
        await counterB.increment(2);
        await counterB.decrement(1);

        final merged = InMemoryLocalStore()..init();
        await merged.ingestRemoteOps('a', await storeA.opsForDoc('likes_1'));
        await merged.ingestRemoteOps('b', await storeB.opsForDoc('likes_1'));

        final result = await SyncedCounter.open(
          docId: 'likes_1',
          store: merged,
          clock: HlcClock('observer'),
        );
        expect(result.value, 4); // 3 + 2 - 1
      },
    );
  });
}
