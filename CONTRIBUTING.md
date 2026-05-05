# Contributing to Pixel Climb

Thank you for taking the time to contribute. This document covers everything you need to get started.

---

## Reporting Bugs

Open an issue and include the following:

- The script or feature involved
- Steps to reproduce the problem
- What you expected to happen and what actually happened
- Platform (PC / mobile / console) and whether it occurs in Studio or a live server

---

## Suggesting Changes

Open an issue before writing code for anything non-trivial. A short description of the problem and your proposed solution is enough. This avoids duplicate work and ensures the change fits the project's direction.

---

## Pull Requests

1. Fork the repository and create a branch from `main`.
2. Name the branch after what it does: `fix/checkpoint-save-race` or `feat/leaderboard-pagination`.
3. Keep commits small and focused. Write commit messages in the present tense: `Fix data loss on rapid checkpoint touches`, not `Fixed` or `Fixes data loss`.
4. Open a pull request against `main` with a clear description of what changed and why.

---

## Code Style

These conventions match the existing codebase. Please follow them in all new and modified scripts.

- Use `--!strict` at the top of every file.
- Declare types on function parameters and return values where practical.
- Wrap all DataStore calls in `pcall`. Use `warn` for non-fatal failures, not `error`.
- Never `print` or `warn` in production paths without a system prefix, e.g. `[CheckpointSystem]`.
- Favour `task.spawn` and `task.delay` over deprecated `spawn` and `delay`.
- Keep configuration values in a top-level `CONFIG` table rather than scattered as magic numbers.
- One script, one responsibility. Do not add unrelated logic to an existing file.

---

## What Not to Touch

The `legacy/` directory contains the original script revisions preserved for historical reference. Do not modify or delete those files; changes belong in `src/`.
