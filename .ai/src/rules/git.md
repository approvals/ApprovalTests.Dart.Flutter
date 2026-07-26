# Git Rules

One logical change per commit, message in Arlo's Commit Notation, generated artefacts stay out of history.

## Commit message — Arlo's Commit Notation

`CONTRIBUTING.md` mandates Arlo's Commit Notation: a risk symbol, an action symbol, then a concise description — `<risk><action> <description>` (for example `.r rename variable`, `!B fix spelling on label`, `@d update README`).

- **Risk** — `.` provable (trivially verifiable) · `-` tested · `!` single atomic action · `@` other.
- **Action** — `r` refactor · `e` environment/non-code · `d` documentation · `t` test-only · `F` feature · `B` bugfix.
- Pick the risk honestly: `.` only when the change is self-evidently correct, `-` only when you actually ran the tests, `!` for one atomic edit, `@` otherwise.
- One logical change per commit; split unrelated work. Keep the description imperative and ≤72 chars.
- Record the human author only — no `Co-Authored-By:`, `Generated with …`, or agent/model trailers.

## Pull requests

- Discuss non-trivial changes with the repository owners (issue or email) before starting.
- Update `README.md` for any interface change, and bump the version in `pubspec.yaml`, example files, and `README.md` to the version the PR represents.
- Merge only after sign-off from two other developers; ask a second reviewer to merge if you lack permission.
- Resolve hook or CI failures at the source rather than passing `--no-verify`.

## Branches

- Descriptive names: `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`. Rebase onto `main` before opening a PR.

## Keep out of history

- Generated artefacts (`*.received.*`, the `.approval_tests/` cache), lockfile binaries, secrets, and `.env*` files stay out of the repo; fence them with `.gitignore`.
