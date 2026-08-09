import 'hlc.dart';

/// A node's mutable Hybrid Logical Clock cursor.
///
/// One [HlcClock] should be shared by every [SyncedDoc], [SyncedCounter]
/// and [SyncedSet] backed by the same [LocalStore]/node id, so that a
/// write immediately following an observed remote operation is guaranteed
/// to sort after it.
class HlcClock {
  final String nodeId;
  Hlc _last;

  HlcClock(this.nodeId) : _last = Hlc.zero(nodeId);

  /// The most recently produced or observed timestamp.
  Hlc get last => _last;

  /// Produces a new local timestamp strictly greater than every timestamp
  /// this clock has produced or observed so far. Call once per local
  /// write.
  Hlc next() {
    _last = Hlc.now(nodeId, previous: _last);
    return _last;
  }

  /// Folds a timestamp observed on an incoming remote operation into this
  /// clock, so subsequent [next] calls sort after it. Call once per
  /// applied remote operation (or once per batch, using the batch's
  /// greatest [Hlc]).
  void observe(Hlc remote) {
    _last = Hlc.receive(nodeId, remote: remote, local: _last);
  }
}
