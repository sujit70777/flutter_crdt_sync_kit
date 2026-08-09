import 'package:meta/meta.dart';

/// A Hybrid Logical Clock timestamp.
///
/// HLCs combine wall-clock time with a logical counter so that concurrent
/// events on different nodes can be totally ordered deterministically, even
/// when device clocks disagree or drift. Every [Operation] in sync_kit is
/// stamped with an [Hlc]; CRDT merge functions use [compareTo] to decide
/// which of two concurrent writes "wins".
///
/// The algorithm follows Kulkarni et al., "Logical Physical Clocks and
/// Consistent Snapshots in Globally Distributed Databases".
@immutable
class Hlc implements Comparable<Hlc> {
  /// Milliseconds since the Unix epoch, per this node's local clock.
  final int millis;

  /// Logical counter used to disambiguate multiple events within the same
  /// millisecond, or to advance the clock past a remote clock reading equal
  /// or greater physical time.
  final int counter;

  /// Identifier of the node that produced this timestamp. Used only as the
  /// final, deterministic tie-breaker when [millis] and [counter] are equal.
  final String nodeId;

  const Hlc({
    required this.millis,
    required this.counter,
    required this.nodeId,
  });

  /// The zero value for a given node, older than any timestamp produced by
  /// [now] or [receive].
  factory Hlc.zero(String nodeId) => Hlc(millis: 0, counter: 0, nodeId: nodeId);

  /// Creates a new local timestamp, guaranteed to be strictly greater than
  /// [previous] (the last timestamp this node produced), even if the wall
  /// clock has not advanced or has moved backwards.
  factory Hlc.now(String nodeId, {Hlc? previous, int? physicalMillis}) {
    final physical =
        physicalMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    if (previous == null) {
      return Hlc(millis: physical, counter: 0, nodeId: nodeId);
    }
    if (physical > previous.millis) {
      return Hlc(millis: physical, counter: 0, nodeId: nodeId);
    }
    return Hlc(
      millis: previous.millis,
      counter: previous.counter + 1,
      nodeId: nodeId,
    );
  }

  /// Merges a locally observed clock ([local], possibly null on first
  /// contact) with a [remote] timestamp received alongside an incoming
  /// operation, producing a new local timestamp that is greater than both.
  ///
  /// This must be called whenever a remote operation is applied, so that
  /// subsequent local writes are ordered causally after everything this
  /// node has observed.
  factory Hlc.receive(
    String nodeId, {
    required Hlc remote,
    Hlc? local,
    int? physicalMillis,
  }) {
    final physical =
        physicalMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final localMillis = local?.millis ?? 0;
    final localCounter = local?.counter ?? 0;
    final maxMillis = [
      physical,
      localMillis,
      remote.millis,
    ].reduce((a, b) => a > b ? a : b);

    if (maxMillis == localMillis && maxMillis == remote.millis) {
      return Hlc(
        millis: maxMillis,
        counter:
            (localCounter > remote.counter ? localCounter : remote.counter) + 1,
        nodeId: nodeId,
      );
    }
    if (maxMillis == localMillis) {
      return Hlc(millis: maxMillis, counter: localCounter + 1, nodeId: nodeId);
    }
    if (maxMillis == remote.millis) {
      return Hlc(
        millis: maxMillis,
        counter: remote.counter + 1,
        nodeId: nodeId,
      );
    }
    return Hlc(millis: maxMillis, counter: 0, nodeId: nodeId);
  }

  /// Parses the canonical wire format produced by [toString].
  factory Hlc.parse(String value) {
    final parts = value.split('-');
    if (parts.length < 3) {
      throw FormatException('Invalid Hlc string: $value');
    }
    final millis = int.parse(parts[0]);
    final counter = int.parse(parts[1]);
    final nodeId = parts.sublist(2).join('-');
    return Hlc(millis: millis, counter: counter, nodeId: nodeId);
  }

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return nodeId.compareTo(other.nodeId);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
  bool operator <=(Hlc other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      millis == other.millis &&
      counter == other.counter &&
      nodeId == other.nodeId;

  @override
  int get hashCode => Object.hash(millis, counter, nodeId);

  /// Canonical, sortable-as-string wire format: `millis-counter-nodeId`.
  /// Zero-padded so that lexicographic string ordering matches [compareTo]
  /// for equal-width millis (used for compact storage/indexing).
  @override
  String toString() =>
      '${millis.toString().padLeft(15, '0')}-${counter.toString().padLeft(6, '0')}-$nodeId';
}
