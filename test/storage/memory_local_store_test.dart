import 'package:flutter_crdt_sync_kit/src/storage/memory/memory_local_store.dart';

import 'local_store_contract.dart';

void main() {
  runLocalStoreContractTests(
    'InMemoryLocalStore',
    () async => InMemoryLocalStore(),
  );
}
