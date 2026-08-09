## 0.1.0

Initial release.

* **Op log + LWW-Register CRDT** — every write is captured as an immutable, HLC-stamped `Operation`; field-level last-write-wins merge is deterministic regardless of delivery order.
* **G-Counter / PN-Counter** — grow-only and increment/decrement counters, idempotent under at-least-once delivery.
* **OR-Set** — add/remove collection CRDT with add-wins semantics for concurrent add/remove of the same element.
* **Local persistence** — `InMemoryLocalStore` (pure Dart) and `DriftLocalStore` (SQLite via `drift`), sharing one behavioral contract test suite.
* **`SyncedDoc<T>` / `SyncedCounter` / `SyncedSet<E>`** — reactive, offline-first public API backed by the CRDTs above.
* **`SyncEngine`** — background push/pull sync loop with batching, exponential backoff retry, connectivity-aware triggering, and realtime-adapter hinting.
* **`SupabaseSyncAdapter`** — push/pull via a Postgres table plus Supabase Realtime.
* **`RestSyncAdapter`** — push/pull against any backend implementing sync_kit's generic REST op-log contract.
* **`AesGcmOpEncryptor`** — optional end-to-end encryption of operation payloads at the sync boundary.
* **`SyncKitInspector`** — debug-mode widget visualizing the op log and live sync activity.
* Example app: two independent "devices" editing a shared to-do, vote counter and tag set, with an offline toggle per device, demonstrating live conflict-free merge.
