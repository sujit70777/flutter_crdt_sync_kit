import 'package:flutter_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hlc.now', () {
    test('advances counter when physical clock has not moved', () {
      final t0 = Hlc.now('node-a', physicalMillis: 1000);
      final t1 = Hlc.now('node-a', previous: t0, physicalMillis: 1000);
      final t2 = Hlc.now('node-a', previous: t1, physicalMillis: 1000);

      expect(t1.millis, 1000);
      expect(t1.counter, 1);
      expect(t2.counter, 2);
      expect(t1 > t0, isTrue);
      expect(t2 > t1, isTrue);
    });

    test('resets counter when physical clock advances', () {
      final t0 = Hlc.now('node-a', physicalMillis: 1000);
      final t1 = Hlc.now('node-a', previous: t0, physicalMillis: 1000);
      final t2 = Hlc.now('node-a', previous: t1, physicalMillis: 2000);

      expect(t2.millis, 2000);
      expect(t2.counter, 0);
      expect(t2 > t1, isTrue);
    });

    test('still advances when the local wall clock moves backwards', () {
      final t0 = Hlc.now('node-a', physicalMillis: 5000);
      final t1 = Hlc.now('node-a', previous: t0, physicalMillis: 1000);

      expect(t1.millis, 5000);
      expect(t1.counter, 1);
      expect(t1 > t0, isTrue);
    });
  });

  group('Hlc.receive', () {
    test('jumps ahead of a remote clock that is in the future', () {
      final local = Hlc.now('node-a', physicalMillis: 1000);
      final remote = Hlc(millis: 5000, counter: 3, nodeId: 'node-b');

      final merged = Hlc.receive(
        'node-a',
        remote: remote,
        local: local,
        physicalMillis: 1000,
      );

      expect(merged.millis, 5000);
      expect(merged.counter, 4);
      expect(merged > remote, isTrue);
      expect(merged > local, isTrue);
    });

    test('keeps local physical time when it leads, bumping the counter', () {
      final local = Hlc.now('node-a', physicalMillis: 9000);
      final remote = Hlc(millis: 1000, counter: 9, nodeId: 'node-b');

      final merged = Hlc.receive(
        'node-a',
        remote: remote,
        local: local,
        physicalMillis: 9000,
      );

      expect(merged.millis, 9000);
      expect(merged.counter, local.counter + 1);
      expect(merged > local, isTrue);
      expect(merged > remote, isTrue);
    });

    test('takes the max counter + 1 when all three clocks tie on millis', () {
      final local = Hlc(millis: 1000, counter: 2, nodeId: 'node-a');
      final remote = Hlc(millis: 1000, counter: 7, nodeId: 'node-b');

      final merged = Hlc.receive(
        'node-a',
        remote: remote,
        local: local,
        physicalMillis: 1000,
      );

      expect(merged.millis, 1000);
      expect(merged.counter, 8);
    });

    test('result is always greater than both inputs (causal consistency)', () {
      for (var i = 0; i < 200; i++) {
        final local = Hlc(
          millis: 1000 + i % 7,
          counter: i % 5,
          nodeId: 'node-a',
        );
        final remote = Hlc(
          millis: 1000 + (i * 3) % 11,
          counter: i % 4,
          nodeId: 'node-b',
        );
        final physical = 1000 + i % 13;

        final merged = Hlc.receive(
          'node-a',
          remote: remote,
          local: local,
          physicalMillis: physical,
        );

        expect(merged > local, isTrue, reason: 'merged=$merged local=$local');
        expect(
          merged > remote,
          isTrue,
          reason: 'merged=$merged remote=$remote',
        );
      }
    });
  });

  group('ordering & tie-breaking', () {
    test('compares by millis, then counter, then nodeId', () {
      final a = Hlc(millis: 100, counter: 0, nodeId: 'a');
      final b = Hlc(millis: 200, counter: 0, nodeId: 'a');
      final c = Hlc(millis: 200, counter: 1, nodeId: 'a');
      final d = Hlc(millis: 200, counter: 1, nodeId: 'z');
      final e = Hlc(millis: 200, counter: 1, nodeId: 'b');

      expect(a < b, isTrue);
      expect(b < c, isTrue);
      expect(c < e, isTrue);
      expect(e < d, isTrue);
    });

    test('is a total order usable for deterministic sorting', () {
      final clocks = [
        Hlc(millis: 5, counter: 0, nodeId: 'b'),
        Hlc(millis: 5, counter: 0, nodeId: 'a'),
        Hlc(millis: 3, counter: 9, nodeId: 'z'),
        Hlc(millis: 5, counter: 1, nodeId: 'a'),
      ];
      clocks.shuffle();
      clocks.sort();
      expect(clocks.map((c) => c.toString()).toList(), [
        Hlc(millis: 3, counter: 9, nodeId: 'z').toString(),
        Hlc(millis: 5, counter: 0, nodeId: 'a').toString(),
        Hlc(millis: 5, counter: 0, nodeId: 'b').toString(),
        Hlc(millis: 5, counter: 1, nodeId: 'a').toString(),
      ]);
    });
  });

  group('serialization', () {
    test('round-trips through toString/parse', () {
      final original = Hlc(
        millis: 1731234567890,
        counter: 42,
        nodeId: 'device-123',
      );
      final parsed = Hlc.parse(original.toString());
      expect(parsed, original);
    });

    test('string ordering matches compareTo ordering', () {
      final a = Hlc(millis: 100, counter: 0, nodeId: 'a');
      final b = Hlc(millis: 200, counter: 0, nodeId: 'a');
      expect(a.toString().compareTo(b.toString()) < 0, isTrue);
    });
  });
}
