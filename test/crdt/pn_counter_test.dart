import 'package:flutter_crdt_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_crdt_sync_kit/src/crdt/pn_counter.dart';
import 'package:flutter_crdt_sync_kit/src/op/op_kind.dart';
import 'package:flutter_crdt_sync_kit/src/op/operation.dart';
import 'package:flutter_test/flutter_test.dart';

Operation _op(String id, OpKind kind, num delta, String node) => Operation(
  id: id,
  docId: 'stock-1',
  docType: 'inventory',
  field: '',
  kind: kind,
  value: delta,
  hlc: Hlc(millis: 100, counter: 0, nodeId: node),
  nodeId: node,
);

void main() {
  group('PNCounter', () {
    test('increments and decrements net out correctly', () {
      final c = PNCounter();
      c.apply(_op('i1', OpKind.counterIncrement, 10, 'a'));
      c.apply(_op('d1', OpKind.counterDecrement, 3, 'a'));
      c.apply(_op('i2', OpKind.counterIncrement, 1, 'b'));
      expect(c.value, 8);
    });

    test('can go negative', () {
      final c = PNCounter();
      c.apply(_op('i1', OpKind.counterIncrement, 1, 'a'));
      c.apply(_op('d1', OpKind.counterDecrement, 5, 'a'));
      expect(c.value, -4);
    });

    test('converges regardless of application order', () {
      final ops = [
        _op('i1', OpKind.counterIncrement, 10, 'a'),
        _op('d1', OpKind.counterDecrement, 4, 'b'),
        _op('i2', OpKind.counterIncrement, 2, 'c'),
        _op('d2', OpKind.counterDecrement, 1, 'a'),
      ];
      for (final order in [
        ops,
        ops.reversed.toList(),
        [ops[2], ops[0], ops[3], ops[1]],
      ]) {
        final c = PNCounter();
        for (final op in order) {
          c.apply(op);
        }
        expect(c.value, 7, reason: 'order=${order.map((o) => o.id)}');
      }
    });

    test(
      'duplicate delivery of increments and decrements does not skew the result',
      () {
        final incOp = _op('i1', OpKind.counterIncrement, 10, 'a');
        final decOp = _op('d1', OpKind.counterDecrement, 4, 'a');
        final c = PNCounter();
        c.apply(incOp);
        c.apply(decOp);
        c.apply(incOp); // redelivered
        c.apply(decOp); // redelivered
        expect(c.value, 6);
      },
    );
  });
}
