import 'dart:math';

import 'package:flutter_sync_kit/src/crdt/g_counter.dart';
import 'package:flutter_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_sync_kit/src/op/op_kind.dart';
import 'package:flutter_sync_kit/src/op/operation.dart';
import 'package:flutter_test/flutter_test.dart';

Operation _inc(String id, num delta, String node) => Operation(
  id: id,
  docId: 'counter-1',
  docType: 'likes',
  field: '',
  kind: OpKind.counterIncrement,
  value: delta,
  hlc: Hlc(millis: 100, counter: 0, nodeId: node),
  nodeId: node,
);

void main() {
  group('GCounter', () {
    test('sums increments from a single node', () {
      final c = GCounter();
      c.apply(_inc('op1', 1, 'a'));
      c.apply(_inc('op2', 2, 'a'));
      c.apply(_inc('op3', 3, 'a'));
      expect(c.value, 6);
    });

    test('sums increments from multiple nodes regardless of order', () {
      final ops = [_inc('a1', 5, 'a'), _inc('b1', 3, 'b'), _inc('c1', 2, 'c')];
      final orderings = [
        ops,
        ops.reversed.toList(),
        [ops[1], ops[2], ops[0]],
      ];
      for (final order in orderings) {
        final c = GCounter();
        for (final op in order) {
          c.apply(op);
        }
        expect(c.value, 10, reason: 'order=${order.map((o) => o.id)}');
      }
    });

    test('applying the same increment op twice does not double count', () {
      final c = GCounter();
      final op = _inc('op1', 5, 'a');
      c.apply(op);
      c.apply(op);
      c.apply(op);
      expect(c.value, 5);
    });

    test('is commutative and idempotent under random shuffled redelivery', () {
      final random = Random(7);
      final ops = List.generate(
        30,
        (i) => _inc('op-$i', random.nextInt(10), 'node-${i % 5}'),
      );
      final expectedTotal = ops.fold<num>(0, (a, op) => a + (op.value as num));

      for (var trial = 0; trial < 5; trial++) {
        final c = GCounter();
        // Redeliver every op 1-3 times in random order to simulate
        // at-least-once delivery over an unreliable sync channel.
        final redelivered = [
          for (final op in ops)
            for (var r = 0; r < 1 + random.nextInt(3); r++) op,
        ]..shuffle(random);
        for (final op in redelivered) {
          c.apply(op);
        }
        expect(c.value, expectedTotal);
      }
    });
  });
}
