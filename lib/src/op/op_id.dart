import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a globally-unique [Operation.id]. Exposed so custom
/// [SyncAdapter] implementations or tests can mint ids consistently with
/// the rest of sync_kit.
String newOpId() => _uuid.v4();
