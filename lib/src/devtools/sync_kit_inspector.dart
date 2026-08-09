import 'dart:async';

import 'package:flutter/material.dart';

import '../op/op_kind.dart';
import '../op/operation.dart';
import '../storage/local_store.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_event.dart';

/// A debug-mode widget that shows sync_kit's op log and live sync engine
/// activity — useful for understanding *why* two devices merged the way
/// they did while debugging a sync issue.
///
/// Not intended for release builds; wrap it in `if (kDebugMode)` or a
/// debug-only route in your app.
///
/// ```dart
/// if (kDebugMode)
///   FloatingActionButton(
///     onPressed: () => Navigator.of(context).push(MaterialPageRoute(
///       builder: (_) => Scaffold(
///         appBar: AppBar(title: const Text('sync_kit inspector')),
///         body: SyncKitInspector(store: store, engine: engine),
///       ),
///     )),
///     child: const Icon(Icons.bug_report),
///   ),
/// ```
class SyncKitInspector extends StatefulWidget {
  final LocalStore store;
  final SyncEngine? engine;
  final int maxEntries;

  const SyncKitInspector({
    super.key,
    required this.store,
    this.engine,
    this.maxEntries = 300,
  });

  @override
  State<SyncKitInspector> createState() => _SyncKitInspectorState();
}

class _SyncKitInspectorState extends State<SyncKitInspector> {
  List<Operation> _ops = [];
  final List<SyncEvent> _events = [];
  StreamSubscription<OpBatch>? _opsSub;
  StreamSubscription<SyncEvent>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _loadOps();
    _opsSub = widget.store.changes.listen((_) => _loadOps());
    _eventsSub = widget.engine?.events.listen((event) {
      setState(() {
        _events.insert(0, event);
        if (_events.length > widget.maxEntries) {
          _events.removeRange(widget.maxEntries, _events.length);
        }
      });
    });
  }

  Future<void> _loadOps() async {
    final ops = await widget.store.allOps();
    if (!mounted) return;
    setState(() {
      _ops = ops.reversed.take(widget.maxEntries).toList();
    });
  }

  @override
  void dispose() {
    _opsSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Op Log'),
              Tab(text: 'Sync Activity'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildOpLog(context), _buildSyncActivity(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpLog(BuildContext context) {
    if (_ops.isEmpty) {
      return const Center(child: Text('No operations recorded yet.'));
    }
    return ListView.separated(
      itemCount: _ops.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final op = _ops[index];
        return ListTile(
          dense: true,
          leading: _KindBadge(kind: op.kind.wireName),
          title: Text(
            '${op.docType}/${op.docId}${op.field.isEmpty ? '' : '.${op.field}'}',
          ),
          subtitle: Text(
            'value: ${op.value}\nhlc: ${op.hlc} · node: ${op.nodeId}',
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildSyncActivity(BuildContext context) {
    if (widget.engine == null) {
      return const Center(child: Text('No SyncEngine attached.'));
    }
    if (_events.isEmpty) {
      return const Center(child: Text('No sync activity yet.'));
    }
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _SyncEventTile(event: _events[index]),
    );
  }
}

class _KindBadge extends StatelessWidget {
  final String kind;
  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      child: Text(
        kind.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _SyncEventTile extends StatelessWidget {
  final SyncEvent event;
  const _SyncEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (event) {
      SyncCycleStarted() => (Icons.sync, Colors.blueGrey, 'Sync cycle started'),
      SyncCycleSkippedOffline() => (
        Icons.cloud_off,
        Colors.grey,
        'Skipped — offline',
      ),
      SyncCycleCompleted() => (
        Icons.check_circle_outline,
        Colors.blueGrey,
        'Sync cycle completed',
      ),
      SyncPushSucceeded(:final opCount) => (
        Icons.cloud_upload,
        Colors.green,
        'Pushed $opCount operation(s)',
      ),
      SyncPushFailed(:final error, :final attempt, :final nextRetryDelay) => (
        Icons.error_outline,
        Colors.red,
        'Push failed (attempt $attempt): $error — retry in ${nextRetryDelay.inSeconds}s',
      ),
      SyncPullSucceeded(:final opCount) => (
        Icons.cloud_download,
        Colors.green,
        'Pulled $opCount new operation(s)',
      ),
      SyncPullFailed(:final error, :final attempt, :final nextRetryDelay) => (
        Icons.error_outline,
        Colors.red,
        'Pull failed (attempt $attempt): $error — retry in ${nextRetryDelay.inSeconds}s',
      ),
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(text),
      subtitle: Text(event.timestamp.toIso8601String()),
    );
  }
}
