import 'package:flutter/material.dart';
import 'package:flutter_sync_kit/flutter_sync_kit.dart';

import 'demo_backend.dart';
import 'device_panel.dart';
import 'manual_connectivity_monitor.dart';
import 'todo_item.dart';

/// sync_kit's killer demo, as a single-process Flutter app: two
/// independent "devices" (their own [InMemoryLocalStore], [HlcClock] and
/// [SyncEngine]) edit the *same* to-do item, a vote counter, and a tag set
/// while offline. Flip a device to airplane mode, edit both, flip it back
/// online, and watch the merge happen live — with no manual conflict
/// resolution.
void main() {
  runApp(const SyncKitDemoApp());
}

const sharedDocId = 'demo_todo_1';

class SyncKitDemoApp extends StatelessWidget {
  const SyncKitDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sync_kit demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _DemoHome(),
    );
  }
}

class _DemoHome extends StatefulWidget {
  const _DemoHome();

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  // One shared in-memory "server" both devices sync through. Swap
  // DemoSyncAdapter for SupabaseSyncAdapter or RestSyncAdapter to point
  // this demo at a real backend — that's the entire change needed.
  final backend = DemoBackend();
  late final Future<(DeviceSession, DeviceSession)> _sessions =
      _createSessions();

  Future<(DeviceSession, DeviceSession)> _createSessions() async {
    final a = await DeviceSession.create(
      name: 'Device A',
      nodeId: 'device-a',
      backend: backend,
    );
    final b = await DeviceSession.create(
      name: 'Device B',
      nodeId: 'device-b',
      backend: backend,
    );
    return (a, b);
  }

  @override
  void dispose() {
    _sessions.then((s) {
      s.$1.dispose();
      s.$2.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('sync_kit — offline-first CRDT sync')),
      body: FutureBuilder<(DeviceSession, DeviceSession)>(
        future: _sessions,
        builder: (context, snapshot) {
          final sessions = snapshot.data;
          if (sessions == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const _Explainer(),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      final panelA = DevicePanel(session: sessions.$1);
                      final panelB = DevicePanel(session: sessions.$2);
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: panelA),
                                const SizedBox(width: 12),
                                Expanded(child: panelB),
                              ],
                            )
                          : ListView(
                              children: [
                                panelA,
                                const SizedBox(height: 12),
                                panelB,
                              ],
                            );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Both devices edit the same record. Flip a device offline, edit both '
          'devices differently, then flip it back online — the merge happens '
          'automatically, with no lost writes. Expand "sync_kit inspector" on '
          'either panel to see the op log driving it.',
        ),
      ),
    );
  }
}

/// Everything one simulated device needs: its own local store, clock,
/// connectivity switch and sync engine, plus the three CRDT-backed values
/// this demo shows off (a document, a counter, a set).
class DeviceSession {
  final String name;
  final LocalStore store;
  final ManualConnectivityMonitor connectivity;
  final SyncEngine engine;
  final SyncedDoc<TodoItem> doc;
  final SyncedCounter votes;
  final SyncedSet<String> tags;

  DeviceSession._({
    required this.name,
    required this.store,
    required this.connectivity,
    required this.engine,
    required this.doc,
    required this.votes,
    required this.tags,
  });

  static Future<DeviceSession> create({
    required String name,
    required String nodeId,
    required DemoBackend backend,
  }) async {
    final store = InMemoryLocalStore();
    await store.init();
    final clock = HlcClock(nodeId);
    final connectivity = ManualConnectivityMonitor();
    final engine = SyncEngine(
      store: store,
      adapter: DemoSyncAdapter(backend, id: 'demo'),
      connectivity: connectivity,
      pollInterval: const Duration(seconds: 5),
      writeDebounce: const Duration(milliseconds: 200),
    );

    final doc = await SyncedDoc.open<TodoItem>(
      docId: sharedDocId,
      docType: 'todo',
      store: store,
      clock: clock,
      codec: todoCodec,
      empty: TodoItem.empty,
      engine: engine,
    );
    final votes = await SyncedCounter.open(
      docId: '${sharedDocId}_votes',
      store: store,
      clock: clock,
      engine: engine,
    );
    final tags = await SyncedSet.open<String>(
      docId: '${sharedDocId}_tags',
      store: store,
      clock: clock,
      engine: engine,
    );

    engine.start();

    return DeviceSession._(
      name: name,
      store: store,
      connectivity: connectivity,
      engine: engine,
      doc: doc,
      votes: votes,
      tags: tags,
    );
  }

  Future<void> dispose() async {
    await engine.stop();
    await doc.dispose();
    await votes.dispose();
    await tags.dispose();
  }
}
