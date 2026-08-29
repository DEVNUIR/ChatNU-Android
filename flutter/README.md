# ChatNU Flutter migration

This directory is the staged Flutter replacement for the Android presentation layer. The existing Android application and server remain untouched while Flutter reaches feature parity.

## Phase 1 scope

- shared Flutter application shell
- Riverpod state boundary
- go_router route graph
- dark/light ChatNU theme tokens
- balanced/full/reduced Liquid Glass quality architecture
- responsive phone/tablet/desktop chat shell
- polished mock conversation, Markdown, code, model selector and composer
- English/Persian + LTR/RTL foundations

Backend, authentication, persistence, E2EE and realtime are intentionally **not** connected in Phase 1. Their existing Android contracts remain the source of truth for later migration phases.

## Local bootstrap

With Flutter 3.44+ installed:

```bash
cd flutter
./tool/bootstrap_android.sh
flutter run
```

The bootstrap script generates only missing Android platform boilerplate in a temporary directory and copies it into this Flutter workspace, so it does not overwrite the hand-authored project files.
