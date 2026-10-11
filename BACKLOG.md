# BACKLOG

Terse, actionable queue for this repo. No decisions, no metanarrative.

## Open

- [ ] **Adopt melos (Topology C)** — add the `melos:` scripts contract to
      `pubspec.yaml` (`useRootAsPackage: true`, `melos ^8.8.0` dev dep) with
      `analyze`/`test`/`verify` done via `melos run`, and a deep-clean task
      using native `melos clean` (the bible's deep-clean mechanism; removes
      build/, .dart_tool/, .packages). NOTE: AGENTS.md calls this topology-A
      but the bible §3.3 labels a single-package repo **Topology C** — SOURCE
      AGENTS.md deviation text must be corrected too. Verify: `dart run melos
      run verify` green. Do NOT hand-roll a clean:deep; use native `melos
      clean`.

Resolution: doctrine decision t_f0ce8719 (2026-10-11) — **adopt melos**. The
bible §2.1 requires melos for EVERY topology incl. single-package Topology C
(`useRootAsPackage: true`); native `melos clean` is the deep-clean mechanism. The
previous "no-melos is doctrine-OK / clean:deep N/A" reading was corrected by the
operator (re-verified against docs/02-toolchain.md §2.1 and docs/03-topology.md
§3.3) — a single-package repo is still a melos workspace and does not drop melos
to save a file. Closing this gap is tracked as code-fix work above, not accepted
as a deviation.
