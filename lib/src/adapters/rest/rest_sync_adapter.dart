import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../op/operation.dart';
import '../../sync/sync_adapter.dart';

/// A [SyncAdapter] for any backend that speaks sync_kit's generic REST op
/// log contract:
///
/// - `POST {baseUrl}/ops` — body `{"ops": [<operation>, ...]}`, each
///   operation JSON-encoded via [Operation.toJson]. Must respond 2xx once
///   every operation is durably recorded. Operations may arrive more than
///   once (retries) — the endpoint should treat `id` as an idempotency
///   key and ignore duplicates.
/// - `GET {baseUrl}/ops?since={checkpoint}` — `since` is omitted on the
///   very first sync. Responds
///   `{"ops": [<operation>, ...], "checkpoint": "<opaque cursor>"}` with
///   every operation recorded (by any device) after `since`. `checkpoint`
///   is treated as an opaque string by sync_kit — a server sequence
///   number or timestamp both work — and is echoed back as `since` on the
///   next pull.
///
/// Use [headers] to attach auth (e.g. a bearer token); pass a fresh
/// `http.Client` per adapter if you need custom TLS/proxy settings.
class RestSyncAdapter implements SyncAdapter {
  @override
  final String id;

  final Uri baseUrl;
  final http.Client _client;
  final Map<String, String> Function() headers;
  final Duration timeout;

  RestSyncAdapter({
    this.id = 'rest',
    required this.baseUrl,
    http.Client? client,
    Map<String, String> Function()? headers,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       headers = headers ?? (() => const {});

  Uri get _opsUrl => baseUrl.resolve('ops');

  @override
  Future<void> push(List<Operation> ops) async {
    final response = await _client
        .post(
          _opsUrl,
          headers: {'content-type': 'application/json', ...headers()},
          body: jsonEncode({'ops': ops.map((o) => o.toJson()).toList()}),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RestSyncException(
        'push failed: HTTP ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Future<PullResult> pull(String? checkpoint) async {
    final url = checkpoint == null
        ? _opsUrl
        : _opsUrl.replace(queryParameters: {'since': checkpoint});
    final response = await _client
        .get(url, headers: headers())
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RestSyncException(
        'pull failed: HTTP ${response.statusCode} ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final ops = (json['ops'] as List<dynamic>? ?? const [])
        .map((raw) => Operation.fromJson(raw as Map<String, dynamic>))
        .toList();
    return PullResult(ops: ops, nextCheckpoint: json['checkpoint'] as String?);
  }
}

class RestSyncException implements Exception {
  final String message;
  RestSyncException(this.message);

  @override
  String toString() => 'RestSyncException: $message';
}
