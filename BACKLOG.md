# BACKLOG

Terse, actionable queue for this repo. No decisions, no metanarrative.

## Open

(none.)

## Deviations (do NOT auto-fix)

- [ ] **No melos `scripts:` contract / no `clean:deep`** (DECLARED acceptance
      exception, doctrine decision t_f0ce8719). Single-package, no-melos
      topology-A CLI (AGENTS.md Deviations); bible §2.1 melos scripts contract
      targets melos workspaces, and a hand-rolled clean:deep is discouraged for
      a single-package no-melos CLI. The verify-gate criterion "clean:deep
      present" is therefore N/A by declared topology, not silent drift. Do NOT
      hand-add a melos script or restructure into a workspace without a real
      reason. Equivalents: `dart clean` / remove `.dart_tool/` + `build/` by
      hand; verified `git clean -n -fdx` removes only untracked+gitignored
      `.dart_tool/` and `pubspec.lock` (no critical files at risk).
