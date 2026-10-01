# Changelog

## v2.0.0 — 2026-10-01

- New game from the latest web version: three starting points at 18, 10
  decisions across 5 life stages drawn from 42 decisions (12 surprise life
  events), a simplified money model with investment growth and interest,
  a live dashboard, and a Family Wealth Score with your finances at 65, what
  reaches the next generation, and a family protection checklist.
- Real app look: black launch screen with the big logo (no white box on
  Android 12+), new launcher icon sized for round, squircle, and square
  shapes, solid app bar, and About / Privacy / Credits panels.
- Android back button asks before leaving a roadmap, returns to the start
  from results, and asks before exiting.
- Phones and tablets, portrait and landscape: rotates freely, smaller
  start-screen logo on landscape phones.
- Removed the social, fundraising, and "Play another game" links from the new
  web version; a content security policy blocks all network access.
- The `INTERNET` permission that Capacitor merges in is now stripped from the
  final manifest.
- APK renamed to `WGRALGO-GenerationalWealthRoadmap-v2.0.0.apk`, the same
  `WGRALGO-<AppName>-v<version>.apk` naming as every WGRALGO app.
- Version 2.0.0 (versionCode 200). Signed with a new key: uninstall v1.0.0
  before installing v2.0.0.
- Added GitHub Actions debug builds, a signed release workflow, and
  `tools/validate-release.sh`; `tools/build-icons.py` now runs from the repo.

## v1.0.0

- Initial GitHub-ready Android APK release.
- Added offline life-stage financial decision roadmap with 12 stages and 36
  decision choices.
- Added Wealth Score, Emergency Fund, Credit Health, Debt Risk, Investment
  Growth, Family Stability, and Legacy Impact tracking.
- Added final Family Wealth Story summary, rating, strongest / weakest
  category, and three personalized lessons.
- Added Play Again, Restart, and Home navigation.
- Removed website navigation, social media bar, GoFundMe bar, and
  WordPress menu clutter from the APK interface.
- Removed the `INTERNET` permission &mdash; the app is fully offline.
- Replaced placeholder icon and splash with the official Generational
  Wealth Roadmap logo (full-bleed adaptive icon on solid black; no white
  border).
- Bumped package to `org.wgralgo.generationalwealthroadmap`,
  `versionName` `1.0.0`, `versionCode` `100`.
- Wired release signing config, ProGuard / R8 minification, and resource
  shrinking in `android/app/build.gradle`.
- Added GPLv3 LICENSE, PRIVACY.md, CONTRIBUTORS.md, and README.
