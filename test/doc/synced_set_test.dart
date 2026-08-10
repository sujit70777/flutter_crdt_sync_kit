import 'package:flutter_crdt_sync_kit/flutter_crdt_sync_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncedSet', () {
    test('add/remove update elements and stream', () async {
      final store = InMemoryLocalStore();
      await store.init();
      final tags = await SyncedSet.open<String>(
        docId: 'post_1_tags',
        store: store,
        clock: HlcClock('node-a'),
      );

      final snapshots = <Set<String>>[];
      final sub = tags.stream.listen(snapshots.add);

      await tags.add('flutter');
      await tags.add('dart');
      await tags.remove('flutter');
      await Future<void>.delayed(Duration.zero);

      expect(tags.elements, {'dart'});
      expect(snapshots.last, {'dart'});
      await sub.cancel();
    });

    test('removing an absent element is a no-op', () async {
      final store = InMemoryLocalStore();
      await store.init();
      final tags = await SyncedSet.open<String>(
        docId: 's1',
        store: store,
        clock: HlcClock('a'),
      );
      await tags.remove('nope');
      expect(tags.elements, isEmpty);
      expect(await store.opsForDoc('s1'), isEmpty);
    });

    test(
      'concurrent add-on-one-device / remove-on-another is add-wins after merge',
      () async {
        final storeA = InMemoryLocalStore()..init();
        final storeB = InMemoryLocalStore()..init();

        final setA = await SyncedSet.open<String>(
          docId: 'tags_1',
          store: storeA,
          clock: HlcClock('device-a'),
        );
        await setA.add('flutter');

        // Device B starts from the same known state (it observed the add)...
        final setB = await SyncedSet.open<String>(
          docId: 'tags_1',
          store: storeB,
          clock: HlcClock('device-b'),
        );
        await storeB.ingestRemoteOps('sync', await storeA.opsForDoc('tags_1'));
        await Future<void>.delayed(Duration.zero);
        expect(setB.elements, {'flutter'});

        // ...then, concurrently: A adds 'dart', B removes 'flutter' (observing
        // only what it had at the time).
        await setA.add('dart');
        await setB.remove('flutter');

        final merged = InMemoryLocalStore()..init();
        await merged.ingestRemoteOps('a', await storeA.opsForDoc('tags_1'));
        await merged.ingestRemoteOps('b', await storeB.opsForDoc('tags_1'));

        final result = await SyncedSet.open<String>(
          docId: 'tags_1',
          store: merged,
          clock: HlcClock('observer'),
        );
        expect(result.elements, {'dart'});
      },
    );
  });
}
