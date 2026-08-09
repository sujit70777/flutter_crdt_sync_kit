import 'package:flutter/material.dart';
import 'package:flutter_sync_kit/flutter_sync_kit.dart';

import 'main.dart';
import 'todo_item.dart';

/// The UI for one simulated device: an airplane-mode switch and live views
/// of the shared to-do (LWW-Register fields), vote counter (PN-Counter)
/// and tag set (OR-Set), each editable independently while offline.
class DevicePanel extends StatefulWidget {
  final DeviceSession session;
  const DevicePanel({super.key, required this.session});

  @override
  State<DevicePanel> createState() => _DevicePanelState();
}

class _DevicePanelState extends State<DevicePanel> {
  late final TextEditingController _titleController;
  final TextEditingController _tagController = TextEditingController();
  bool _showInspector = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.session.doc.value.title,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(session: session),
              const Divider(),
              _TodoEditor(session: session, titleController: _titleController),
              const SizedBox(height: 12),
              _VotesRow(session: session),
              const SizedBox(height: 12),
              _TagsRow(session: session, tagController: _tagController),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('sync_kit inspector'),
                value: _showInspector,
                onChanged: (v) => setState(() => _showInspector = v),
              ),
              if (_showInspector)
                SizedBox(
                  height: 260,
                  child: SyncKitInspector(
                    store: session.store,
                    engine: session.engine,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  final DeviceSession session;
  const _Header({required this.session});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  @override
  Widget build(BuildContext context) {
    final connectivity = widget.session.connectivity;
    return Row(
      children: [
        Icon(connectivity.online ? Icons.wifi : Icons.airplanemode_active),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.session.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Text('Online'),
        Switch(
          value: connectivity.online,
          onChanged: (v) => setState(() => connectivity.online = v),
        ),
      ],
    );
  }
}

class _TodoEditor extends StatelessWidget {
  final DeviceSession session;
  final TextEditingController titleController;
  const _TodoEditor({required this.session, required this.titleController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TodoItem>(
      stream: session.doc.stream,
      initialData: session.doc.value,
      builder: (context, snapshot) {
        final todo = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (edit, then Save)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => session.doc.update(
                    (t) => t.copyWith(title: titleController.text),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Done'),
              value: todo.done,
              onChanged: (v) =>
                  session.doc.update((t) => t.copyWith(done: v ?? false)),
            ),
            Text(
              'Merged value: "${todo.title}" · done: ${todo.done}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _VotesRow extends StatelessWidget {
  final DeviceSession session;
  const _VotesRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<num>(
      stream: session.votes.stream,
      initialData: session.votes.value,
      builder: (context, snapshot) {
        return Row(
          children: [
            const Expanded(
              child: Text(
                'Votes (PN-Counter):',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => session.votes.decrement(),
            ),
            const SizedBox(width: 4),
            Text(
              '${snapshot.data}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => session.votes.increment(),
            ),
          ],
        );
      },
    );
  }
}

class _TagsRow extends StatelessWidget {
  final DeviceSession session;
  final TextEditingController tagController;
  const _TagsRow({required this.session, required this.tagController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: session.tags.stream,
      initialData: session.tags.elements,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tags (OR-Set):'),
            Wrap(
              spacing: 6,
              children: [
                for (final tag in tags)
                  Chip(
                    label: Text(tag),
                    onDeleted: () => session.tags.remove(tag),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: const InputDecoration(labelText: 'Add tag'),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
              ],
            ),
          ],
        );
      },
    );
  }

  void _addTag() {
    final value = tagController.text.trim();
    if (value.isEmpty) return;
    session.tags.add(value);
    tagController.clear();
  }
}
