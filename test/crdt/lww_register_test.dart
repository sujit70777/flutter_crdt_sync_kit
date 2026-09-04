import 'dart:math';

import 'package:flutter_crdt_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_crdt_sync_kit/src/crdt/lww_register.dart';
import 'package:flutter_crdt_sync_kit/src/op/op_kind.dart';
import 'package:flutter_crdt_sync_kit/src/op/operation.dart';
import 'package:flutter_test/flutter_test.dart';

Operation _lww(String id, String value, Hlc hlc) => Operation(
  id: id,
  docId: 'doc-1',
  docType: 'note',
  field: 'title',
  kind: OpKind.lwwSet,
  value: value,
  hlc: hlc,
  nodeId: hlc.nodeId,
);

void main() {
  group('LwwRegister', () {
    test('later write wins when applied in order', () {
      final reg = LwwRegister<String>('', Hlc.zero('node-a'));
      reg.apply(
        _lww('op1', 'hello', Hlc(millis: 100, counter: 0, nodeId: 'a')),
      );
      reg.apply(
        _lww('op2', 'world', Hlc(millis: 200, counter: 0, nodeId: 'a')),
      );
      expect(reg.value, 'world');
    });

    test('same later write wins when applied out of order', () {
      final reg = LwwRegister<String>('', Hlc.zero('node-a'));
      reg.apply(
        _lww('op2', 'world', Hlc(millis: 200, counter: 0, nodeId: 'a')),
      );
      reg.apply(
        _lww('op1', 'hello', Hlc(millis: 100, counter: 0, nodeId: 'a')),
      );
      // The op with the later Hlc always wins, regardless of arrival order.
      expect(reg.value, 'world');
    });

    test('applying the same operation twice is idempotent', () {
      final reg = LwwRegister<String>('', Hlc.zero('node-a'));
      final op = _lww(
        'op1',
        'hello',
        Hlc(millis: 100, counter: 0, nodeId: 'a'),
      );
      reg.apply(op);
      final beforeSecond = reg.value;
      final decision = reg.apply(op);
      expect(reg.value, beforeSecond);
      expect(decision.outcome, ApplyOutcome.ignored);
    });

    test(
      'concurrent writes converge deterministically regardless of delivery order',
      () {
        // Two "concurrent" writes (same millis) from different nodes: the
        // higher nodeId wins the tie-break, and every possible delivery
        // order must reach that same final value.
        final writeA = _lww(
          'a1',
          'from-a',
          Hlc(millis: 100, counter: 0, nodeId: 'node-a'),
        );
        final writeB = _lww(
          'b1',
          'from-b',
          Hlc(millis: 100, counter: 0, nodeId: 'node-b'),
        );
        // 'node-b' > 'node-a' lexicographically, so it should always win.
        final expected = 'from-b';

        for (final order in [
          [writeA, writeB],
          [writeB, writeA],
        ]) {
          final reg = LwwRegister<String>('', Hlc.zero('node-x'));
          for (final op in order) {
            reg.apply(op);
          }
          expect(
            reg.value,
            expected,
            reason: 'order=${order.map((o) => o.id)}',
          );
        }
      },
    );

    test('convergence holds for many random delivery orders of many ops', () {
      final random = Random(42);
      final ops = List.generate(50, (i) {
        final millis = 1000 + random.nextInt(20);
        final counter = random.nextInt(5);
        final node = 'node-${random.nextInt(4)}';
        return _lww(
          'op-$i',
          'value-$i',
          Hlc(millis: millis, counter: counter, nodeId: node),
        );
      });

      // Compute the expected winner deterministically: the op with the
      // greatest Hlc.
      final expectedWinner = ops.reduce((a, b) => a.hlc > b.hlc ? a : b);

      final results = <String>{};
      for (var trial = 0; trial < 10; trial++) {
        final shuffled = List.of(ops)..shuffle(random);
        final reg = LwwRegister<String>('', Hlc.zero('node-x'));
        for (final op in shuffled) {
          reg.apply(op);
        }
        results.add(reg.value);
      }

      expect(results, {expectedWinner.value});
    });

    test(
      'replaying the full history from empty reaches the same state as incremental application',
      () {
        final ops = [
          _lww('op1', 'a', Hlc(millis: 100, counter: 0, nodeId: 'node-a')),
          _lww('op2', 'b', Hlc(millis: 150, counter: 0, nodeId: 'node-b')),
          _lww('op3', 'c', Hlc(millis: 120, counter: 0, nodeId: 'node-c')),
        ];

        final incremental = LwwRegister<String>('', Hlc.zero('node-x'));
        for (final op in ops) {
          incremental.apply(op);
        }

        final replayed = LwwRegister<String>('', Hlc.zero('node-x'));
        for (final op in ops.reversed) {
          replayed.apply(op);
        }

        expect(incremental.value, replayed.value);
        expect(incremental.value, 'b'); // 150ms is the latest
      },
    );
  });
}
