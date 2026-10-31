<!--
Release description template for GitHub Releases. GitHub does not load it
by itself: copy it into the release form, or pass a filled copy with
`gh release create vX.Y.Z --notes-file <file>`.

Before publishing:
- Replace X.Y.Z (this version) and A.B.C (the previous one).
- Write for people who use the app, from the CHANGELOG.md section of this
  version: what they will notice, not how it was done. Plain sentences, no
  em dashes.
- Keep only the sections that have entries. Order: New, Improved, Fixed.
- Keep the upgrade line only when the APKs are signed with the same key as
  the previous release; otherwise tell people to back up, uninstall, then
  restore.
- Keep Privacy only when the release changes what leaves the phone, and
  update docs/privacy-policy.md and the in-app policy with it.
- Publish as Latest (not a draft, not a pre-release), with the tag exactly
  vX.Y.Z: the in-app update check reads releases/latest.
These comments do not show once published; they can be deleted.
-->

# Troona X.Y.Z

<!-- One sentence: the two or three changes people will notice most. -->

## Download

- Most phones: `app-arm64-v8a-release.apk`
- Older 32-bit phones: `app-armeabi-v7a-release.apk`
- Emulators: `app-x86_64-release.apk`

Android 7.0 or later. Install it over A.B.C: your playlists, likes and listening history stay.

## New

<!-- One bullet per feature: a bold name, then what it does and where to find it. -->
- **Feature name** (Settings > Section): what it does for the person using it.

## Improved

- **What changed**: how it feels different now.

## Fixed

<!-- Describe the symptom people saw, then what happens now. -->
- **Short name.** What went wrong, and in which situation. What happens now.

## Privacy

<!-- Only when something new leaves the phone. -->
What is sent, to whom, when, and whether it is on by default. The [privacy policy](https://github.com/donfreddy/troona-music/blob/main/docs/privacy-policy.md) is updated.

**Full changelog**: https://github.com/donfreddy/troona-music/compare/vA.B.C...vX.Y.Z
