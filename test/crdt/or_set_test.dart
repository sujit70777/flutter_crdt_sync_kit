import 'package:flutter_crdt_sync_kit/src/crdt/hlc.dart';
import 'package:flutter_crdt_sync_kit/src/crdt/or_set.dart';
import 'package:flutter_crdt_sync_kit/src/op/op_kind.dart';
import 'package:flutter_crdt_sync_kit/src/op/operation.dart';
import 'package:flutter_test/flutter_test.dart';

Operation _add(String tag, String element, String node) => Operation(
  id: tag,
  docId: 'list-1',
  docType: 'tags',
  field: '',
  kind: OpKind.setAdd,
  value: element,
  hlc: Hlc(millis: 100, counter: 0, nodeId: node),
  nodeId: node,
);

Operation _remove(String id, List<String> tags, String node) => Operation(
  id: id,
  docId: 'list-1',
  docType: 'tags',
  field: '',
  kind: OpKind.setRemove,
  value: tags,
  hlc: Hlc(millis: 200, counter: 0, nodeId: node),
  nodeId: node,
);

void main() {
  group('ORSet', () {
    test('adds accumulate into the set', () {
      final s = ORSet<String>();
      s.apply(_add('t1', 'apple', 'a'));
      s.apply(_add('t2', 'banana', 'a'));
      expect(s.elements, {'apple', 'banana'});
    });

    test('remove observing a tag removes that element', () {
      final s = ORSet<String>();
      s.apply(_add('t1', 'apple', 'a'));
      final tags = s.tagsFor('apple');
      s.apply(_remove('r1', tags, 'a'));
      expect(s.elements, isEmpty);
    });

    test(
      'add-wins: a concurrent add is not erased by a remove that did not observe it',
      () {
        final s = ORSet<String>();
        s.apply(_add('t1', 'apple', 'a'));
        final tags = s.tagsFor('apple'); // remove only observed t1
        // Concurrently, another replica re-adds 'apple' with a new tag.
        s.apply(_add('t2', 'apple', 'b'));
        s.apply(_remove('r1', tags, 'a'));
        // t1 removed, but t2 (unobserved by the remove) keeps 'apple' present.
        expect(s.elements, {'apple'});
      },
    );

    test(
      'remove arriving before its add (out-of-causal-order) still suppresses it',
      () {
        final s = ORSet<String>();
        s.apply(_remove('r1', ['t1'], 'a'));
        s.apply(_add('t1', 'apple', 'a'));
        expect(s.elements, isEmpty);
      },
    );

    test('applying add and remove twice is idempotent', () {
      final s = ORSet<String>();
      final add = _add('t1', 'apple', 'a');
      s.apply(add);
      s.apply(add);
      final remove = _remove('r1', ['t1'], 'a');
      s.apply(remove);
      s.apply(remove);
      expect(s.elements, isEmpty);
    });

    test('converges to the same set regardless of delivery order', () {
      final ops = <Operation>[
        _add('t1', 'apple', 'a'),
        _add('t2', 'banana', 'b'),
        _remove('r1', ['t1'], 'a'),
        _add('t3', 'cherry', 'c'),
      ];
      for (final order in [
        ops,
        ops.reversed.toList(),
        [ops[2], ops[0], ops[3], ops[1]],
        [ops[3], ops[2], ops[1], ops[0]],
      ]) {
        final s = ORSet<String>();
        for (final op in order) {
          s.apply(op);
        }
        expect(s.elements, {
          'banana',
          'cherry',
        }, reason: 'order=${order.map((o) => o.id)}');
      }
    });

    test('re-adding an element after removal makes it a member again', () {
      final s = ORSet<String>();
      s.apply(_add('t1', 'apple', 'a'));
      s.apply(_remove('r1', s.tagsFor('apple'), 'a'));
      expect(s.elements, isEmpty);
      s.apply(_add('t2', 'apple', 'a'));
      expect(s.elements, {'apple'});
    });
  });
}
