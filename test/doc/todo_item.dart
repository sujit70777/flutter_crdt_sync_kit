import 'package:flutter_crdt_sync_kit/flutter_crdt_sync_kit.dart';

class TodoItem {
  final String title;
  final bool done;

  const TodoItem({required this.title, required this.done});

  TodoItem copyWith({String? title, bool? done}) =>
      TodoItem(title: title ?? this.title, done: done ?? this.done);

  static const empty = TodoItem(title: '', done: false);

  @override
  String toString() => 'TodoItem(title: $title, done: $done)';
}

final todoCodec = DocumentCodec<TodoItem>.functional(
  toFields: (t) => {'title': t.title, 'done': t.done},
  fromFields: (f) =>
      TodoItem(title: f['title'] as String, done: f['done'] as bool),
);
