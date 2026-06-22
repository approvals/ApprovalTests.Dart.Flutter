---
name: "arlo-commit-notation"
description: >-
  Use this skill when composing a commit message or preparing a PR for this repository, which follows Arlo's Commit Notation rather than Conventional Commits. Triggers on "commit this", "write a commit message", "save changes", "ship it", "open a PR", "how do I commit here", and Russian phrasings like "закоммить", "сохрани изменения", "оформи коммит", "правила контрибуции". Covers picking the risk and action symbols, the PR process (discuss first, sync README and version, two sign-offs), and the pre-PR gates.
---

# Arlo's Commit Notation

This repo's commit messages use Arlo's Commit Notation (per `CONTRIBUTING.md`), not Conventional Commits. Format every message as `<risk><action> <description>` — the two symbols with no space between them, then one space before the description.

## Compose the message

1. Pick the **risk** symbol by how safe the change is:
   - `.` provable — trivially verifiable (a rename, a constant).
   - `-` tested — a behavior change you covered with a test run.
   - `!` single action — one atomic, indivisible edit.
   - `@` other — anything that does not fit above.
2. Pick the **action** symbol by what the change does:
   - `r` refactor · `e` environment/non-code · `d` documentation · `t` test-only · `F` feature · `B` bugfix.
3. Write a concise, imperative description after one space. Examples:
   - `.r rename variable`
   - `-e update build script`
   - `!B fix spelling on label`
   - `@d update README`
4. Keep one logical change per commit; author as the human only (no AI/tool trailers).

## PR process

- Discuss non-trivial changes with the repository owners (issue or email) before starting.
- Update `README.md` for interface changes; bump the version in `pubspec.yaml`, example files, and `README.md`.
- Run the gates before requesting review — `dart format .`, `flutter analyze`, `flutter test`.
- Merge only after two other developers sign off.

## Gotchas

- Do not default to Conventional Commits (`feat:`, `fix:`) — the documented standard is Arlo's notation. History is mixed, but `CONTRIBUTING.md` is authoritative.
- The risk symbol is a claim about verification — use `-` only if you actually ran the tests, `.` only when the change is self-evidently correct.
- Capital `F`/`B` are feature/bugfix; lowercase `r`/`e`/`d`/`t` are the lower-risk actions. For a pub release, pair with the `release` command for the version-bump and publish checks.
