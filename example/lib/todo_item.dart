import 'package:flutter_sync_kit/flutter_sync_kit.dart';

/// The record both demo "devices" edit — a plain, ordinary Dart class with
/// no sync-specific code in it. sync_kit only needs to know how to turn it
/// into fields ([todoCodec]).
class TodoItem {
  final String title;
  final bool done;

  const TodoItem({required this.title, required this.done});

  TodoItem copyWith({String? title, bool? done}) =>
      TodoItem(title: title ?? this.title, done: done ?? this.done);

  static const empty = TodoItem(title: 'Plan launch party', done: false);
}

final todoCodec = DocumentCodec<TodoItem>.functional(
  toFields: (t) => {'title': t.title, 'done': t.done},
  fromFields: (f) =>
      TodoItem(title: f['title'] as String, done: f['done'] as bool),
);
