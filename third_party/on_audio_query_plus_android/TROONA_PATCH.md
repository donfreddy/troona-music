# Vendored on_audio_query_plus_android 1.2.2

Copied from pub.dev (BSD 3-Clause, see LICENSE) and used through
`dependency_overrides` in the app's `pubspec.yaml`.

Patches, all marked `Troona patch` in the sources:

1. `PermissionController`: require `READ_MEDIA_AUDIO` only on Android 13+,
   and `READ_EXTERNAL_STORAGE` only below. Upstream also required
   `READ_MEDIA_IMAGES` and `WRITE_EXTERNAL_STORAGE`, which forced the app to
   declare photo and write permissions it does not use: Google Play rejects
   `READ_MEDIA_IMAGES` without a core photo use case.
2. `OnAudioQueryPlugin.onMethodCall`: return after replying
   `MissingPermissions`; upstream ran the query anyway and replied twice.

To upgrade: copy the new version over this folder, re-apply both patches,
keep this file.
