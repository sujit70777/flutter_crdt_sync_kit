/// sync_kit: an offline-first, CRDT-based local data layer for Flutter.
///
/// Write while offline, merge automatically and conflict-free when back
/// online, against any backend. See the package README for a full
/// architecture overview and usage guide.
library;

export 'src/crdt/hlc.dart';
export 'src/crdt/hlc_clock.dart';
export 'src/crdt/lww_register.dart'
    show LwwRegister, MergeDecision, ApplyOutcome;
export 'src/crdt/g_counter.dart';
export 'src/crdt/pn_counter.dart';
export 'src/crdt/or_set.dart';

export 'src/op/op_kind.dart';
export 'src/op/operation.dart';
export 'src/op/op_id.dart';

export 'src/storage/local_store.dart';
export 'src/storage/memory/memory_local_store.dart';
export 'src/storage/drift/drift_local_store.dart';

export 'src/doc/document_codec.dart';
export 'src/doc/synced_doc.dart';
export 'src/doc/synced_counter.dart';
export 'src/doc/synced_set.dart';

export 'src/sync/sync_adapter.dart';
export 'src/sync/sync_engine.dart';
export 'src/sync/sync_event.dart';
export 'src/sync/retry_policy.dart';
export 'src/sync/connectivity_monitor.dart';
export 'src/sync/connectivity_plus_monitor.dart';

export 'src/crypto/op_encryptor.dart';
export 'src/crypto/aes_gcm_op_encryptor.dart';

export 'src/adapters/supabase/supabase_sync_adapter.dart';
export 'src/adapters/rest/rest_sync_adapter.dart';

export 'src/devtools/sync_kit_inspector.dart';
