# sync_kit

An offline-first, CRDT-based local data layer for Flutter. Write while offline, merge
automatically and conflict-free when back online, against any backend.

- **CRDT-based** — merges never require manual conflict resolution for the common cases:
  last-write-wins fields, grow-only/PN counters, and add/remove sets.
- **Backend-agnostic** — ship with a Supabase adapter and a generic REST adapter; implement
  `SyncAdapter` yourself for anything else (Firebase, PocketBase, a custom server).
- **Degrades gracefully** — works fully offline indefinitely; syncs opportunistically.

```dart
final doc = await SyncedDoc.open<TodoItem>(
  docId: 'todo_123',
  docType: 'todo',
  store: store,
  clock: clock,
  codec: todoCodec,
  empty: TodoItem.empty,
  engine: engine,
);
doc.update((t) => t.copyWith(done: true)); // works offline instantly
doc.stream.listen((t) => setState(() {})); // reflects local + remote merges
```

Run the example app (`cd example && flutter run -d chrome`) to see two independent
"devices" edit the same record, a counter and a tag set — flip either one offline, edit
both, flip it back online, and watch the merge happen live with nothing lost.

## Why op-based CRDTs

sync_kit never stores just a document's final value. Every write — local or remote — is
captured as an immutable `Operation`, stamped with a [Hybrid Logical Clock](lib/src/crdt/hlc.dart)
(`Hlc`). That op log is what makes merging safe: two devices that were offline and each
generated different operations can replay the *other's* operations against their own
state, in any order, any number of times, and always converge on the same result.

## Architecture

```
Operation (id, docId, field, kind, value, hlc)
   │
   ├── appended to ──▶ LocalStore (InMemoryLocalStore | DriftLocalStore)
   │                       │
   │                       ├─ opsForDoc(docId) ──▶ replayed through CRDT merge
   │                       │                        (LwwRegister / GCounter / PNCounter / ORSet)
   │                       │                        by SyncedDoc / SyncedCounter / SyncedSet
   │                       │
   │                       └─ changes stream ──▶ notifies live Synced* instances
   │
   └── pushed/pulled by ──▶ SyncEngine ──▶ SyncAdapter (Supabase | REST | your own)
```

- **CRDT layer** (`lib/src/crdt`) — pure Dart, no I/O. `Hlc`/`HlcClock` for ordering;
  `LwwRegister`, `GCounter`, `PNCounter`, `ORSet` for merge semantics. This is the part
  that has to be bulletproof, and it's the most heavily tested part of the package.
- **Storage layer** (`lib/src/storage`) — `LocalStore` is a small, CRDT-agnostic interface:
  append operations, fetch them back, track per-adapter push/checkpoint state, dedupe by
  operation id. `InMemoryLocalStore` and `DriftLocalStore` (SQLite) both pass the exact
  same contract test suite (`test/storage/local_store_contract.dart`), so they're
  interchangeable.
- **Document layer** (`lib/src/doc`) — `SyncedDoc<T>`, `SyncedCounter`, `SyncedSet<E>` wire
  a `LocalStore` + `HlcClock` + CRDT type together into the reactive public API.
- **Sync layer** (`lib/src/sync`) — `SyncEngine` drives push → pull cycles: batches pending
  ops, pushes them, pulls remote ops since the last checkpoint, and lets `LocalStore`
  dedupe + fan them out to whichever `SyncedDoc`/`SyncedCounter`/`SyncedSet` is live.
  Retries follow exponential backoff (`RetryPolicy`); a `ConnectivityMonitor` avoids
  futile attempts while offline and re-syncs promptly on reconnect.

## CRDT types

| Type | Use case | File |
|---|---|---|
| `LwwRegister` | "edit a field" — used per-field inside `SyncedDoc` | [`lww_register.dart`](lib/src/crdt/lww_register.dart) |
| `GCounter` | grow-only counts | [`g_counter.dart`](lib/src/crdt/g_counter.dart) |
| `PNCounter` | increment/decrement counters (`SyncedCounter`) | [`pn_counter.dart`](lib/src/crdt/pn_counter.dart) |
| `ORSet` | add/remove collections (`SyncedSet`), add-wins | [`or_set.dart`](lib/src/crdt/or_set.dart) |

Ordered lists/rich text (RGA or similar) are the hardest CRDT to get right and are **not**
implemented in this v0.1 — see [Roadmap](#roadmap).

## Getting started

```yaml
dependencies:
  flutter_crdt_sync_kit: ^0.1.0
```

### 1. Define a codec for your model

`SyncedDoc<T>` tracks each field of `T` as its own LWW-Register, so it needs to know how
to flatten `T` to a field map and back:

```dart
class TodoItem {
  final String title;
  final bool done;
  const TodoItem({required this.title, required this.done});
  TodoItem copyWith({String? title, bool? done}) =>
      TodoItem(title: title ?? this.title, done: done ?? this.done);
  static const empty = TodoItem(title: '', done: false);
}

final todoCodec = DocumentCodec<TodoItem>.functional(
  toFields: (t) => {'title': t.title, 'done': t.done},
  fromFields: (f) => TodoItem(title: f['title'] as String, done: f['done'] as bool),
);
```

### 2. Wire up storage, a clock, and (optionally) a sync engine

```dart
final store = await DriftLocalStore.open(); // or InMemoryLocalStore() for a quick start
final clock = HlcClock(myDeviceId); // share one HlcClock per store/node

final engine = SyncEngine(
  store: store,
  adapter: SupabaseSyncAdapter(client: supabase),
  connectivity: ConnectivityPlusMonitor(),
)..start();
```

### 3. Open and use a document

```dart
final doc = await SyncedDoc.open<TodoItem>(
  docId: 'todo_123',
  docType: 'todo',
  store: store,
  clock: clock,
  codec: todoCodec,
  empty: TodoItem.empty,
  engine: engine,
);

await doc.update((t) => t.copyWith(done: true)); // instant, offline-safe
doc.stream.listen((t) => print(t.title));
```

### Counters and sets

```dart
final likes = await SyncedCounter.open(docId: 'post_1_likes', store: store, clock: clock, engine: engine);
await likes.increment();

final tags = await SyncedSet<String>.open(docId: 'post_1_tags', store: store, clock: clock, engine: engine);
await tags.add('flutter');
```

## Backend adapters

### Supabase

```sql
create table sync_kit_ops (
  server_seq bigint generated always as identity primary key,
  id text not null unique,
  doc_id text not null,
  doc_type text not null,
  field text not null,
  kind text not null,
  value_json jsonb not null,
  hlc_millis bigint not null,
  hlc_counter bigint not null,
  hlc_node_id text not null,
  node_id text not null,
  created_at timestamptz not null default now()
);
create index sync_kit_ops_doc_id_idx on sync_kit_ops (doc_id);
alter table sync_kit_ops enable row level security;
-- add RLS policies scoping rows to your app's tenancy model.
alter publication supabase_realtime add table sync_kit_ops;
```

```dart
final adapter = SupabaseSyncAdapter(client: supabaseClient);
```

Pushes upsert on `id` (idempotent under retry); pulls page through rows by `server_seq`,
which doubles as the sync checkpoint. Implements `RealtimeSyncAdapter`, so `SyncEngine`
pulls promptly on any insert instead of waiting for the poll interval.

### Generic REST

Implement two endpoints against any backend:

- `POST {baseUrl}/ops` — body `{"ops": [<operation>, ...]}`. Treat `id` as an idempotency
  key.
- `GET {baseUrl}/ops?since={checkpoint}` — returns
  `{"ops": [...], "checkpoint": "<opaque cursor>"}` with everything recorded after
  `since` (omitted on the first sync).

```dart
final adapter = RestSyncAdapter(baseUrl: Uri.parse('https://api.example.com/'));
```

### Your own backend

Implement `SyncAdapter` (`push`/`pull`); implement `RealtimeSyncAdapter` too if your
backend can push change notifications.

## Encrypting the op log

```dart
final key = await AesGcmOpEncryptor.deriveKeyFromPassphrase(passphrase, salt: salt);
final engine = SyncEngine(store: store, adapter: adapter, encryptor: AesGcmOpEncryptor(key));
```

Operation values are AES-256-GCM encrypted immediately before `SyncAdapter.push` and
decrypted immediately after `SyncAdapter.pull` — the local op log and every CRDT merge
always see plaintext; only what leaves the device over the network is encrypted. A
backend using this can see routing metadata (`id`, `docId`, `hlc`, `kind`) but not field
values. You are responsible for distributing `secretKey` to a document's readers/writers.

## Debugging: the conflict inspector

```dart
if (kDebugMode)
  SyncKitInspector(store: store, engine: engine)
```

Shows the live op log and sync engine activity (push/pull success, failures, retries) —
useful for understanding *why* two devices merged the way they did.

## Testing your own app

`InMemoryLocalStore` plus `AlwaysOnlineMonitor` (the default) make it easy to unit-test
merge behavior without any I/O — see `test/doc/synced_doc_test.dart` for the pattern of
running two independent stores/clocks "offline", then merging their op logs into a third
store to assert on the converged result.

## Roadmap

- RGA (or similar) CRDT for ordered lists / collaborative text — the hardest CRDT here,
  intentionally deferred past this well-tested LWW/counter/set v0.1.
- Firebase and PocketBase adapters.
- A companion `sync_kit_devtools` Flutter DevTools extension (today, `SyncKitInspector`
  covers the same need as an in-app widget).

## License

MIT — see [LICENSE](LICENSE).
