import 'package:flutter_sync_kit/src/storage/drift/drift_local_store.dart';

import 'local_store_contract.dart';

void main() {
  runLocalStoreContractTests(
    'DriftLocalStore',
    () async => DriftLocalStore.memory(),
  );
}
