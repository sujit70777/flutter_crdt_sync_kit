# sync_kit example

The killer demo: two independent "devices" — each with their own `InMemoryLocalStore`,
`HlcClock` and `SyncEngine` — edit the same to-do item (LWW-Register fields), a vote
counter (PN-Counter) and a tag set (OR-Set) at the same time.

Flip a device to airplane mode with the switch, edit both devices differently, flip it
back online, and watch the merge happen automatically — no lost writes, no manual
conflict resolution. Expand "sync_kit inspector" on either panel to see the op log and
live sync activity driving it.

Both devices sync through an in-memory stand-in backend (`DemoBackend`/`DemoSyncAdapter`
in `lib/demo_backend.dart`) so the demo runs standalone with no setup. Swapping in
`SupabaseSyncAdapter` or `RestSyncAdapter` from the `flutter_sync_kit` package is the only
change needed to point this at a real backend.

Run it with:

```sh
flutter run -d chrome   # or any connected device/simulator
```
