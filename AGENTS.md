# Agent Guidelines for `pitches`

This document defines core principles, architectural invariants, and non-negotiable safety rules for AI agents working on the `pitches` repository.

______________________________________________________________________

## 1. Project Overview & Architecture

`pitches` is a minimal pitch library in Zig. It names pitches, transposes them, and resolves them to frequencies through an explicit tuning. It knows nothing about time, scores, or audio.

- **Pure Zig, `std` Only**: `build.zig.zon` has no dependencies, and it must stay that way. In particular, do not depend on `phrases` (time and score structure) or `lightmix` (audio): `pitches` and `phrases` do not know each other, and a consumer connects them.
- **Library Package**: The public module is registered as `pitches` via `b.addModule` in `build.zig`, so downstream projects consume it with `b.dependency("pitches", .{})`.
- **Consumers**: Consumers pin `pitches` to a commit hash in their `build.zig.zon`, so a change here reaches them only when they bump that pin. Treat a change to a public type's fields, a function signature, an error set, or a numeric result (such as the frequency `EqualTemperament.freq` returns) as a breaking change, and state it in the PR description.
- **Target Language Version**: Zig `0.16.0`, matching the toolchain pinned in `flake.nix`.
- **Development Environment**: Managed with Nix, `direnv`, and `nix-direnv`. Formatting across all languages is handled via `treefmt` (nixfmt, zig fmt, actionlint, mdformat, shellcheck, shfmt).
- **Source Layout** (`src/`):
  - `root.zig`: Re-exports every public symbol.
  - `pitch.zig`: `Pitch` (`code` and `octave`) and `Pitch.Code`, with `midi`, `fromMidi` and `add`.
  - `equal-temperament.zig`: `EqualTemperament`, 12-tone equal temperament referenced to `a4` (`freq` returns Hz).
- **Domain Conventions**:
  - A `Pitch` is data only. It holds no tuning: anything that depends on a choice of reference frequency or temperament belongs to a tuning type, never to `Pitch`.
  - A tuning is a value (a struct whose fields are its parameters, such as `a4`) with a `freq(self, pitch: Pitch) f64` method.
  - `Code` uses sharps only (`cs`, `ds`, ...). The MIDI note number is `12 * (octave + 1) + code`, so C4 is 60 and A4 is 69.
  - `octave` is a `usize`, so the lowest pitch is C0 (MIDI 12). Operations that would go below it, or past the largest MIDI number a `usize` holds, return `error.PitchOutOfRange`; never clamp silently and never overflow.

______________________________________________________________________

## 2. Strict Safety & Operational Rules (Always Enforced)

- **A change request implies commit, push and PR**: When the user instructs a change, carry it through to a pull request without asking for confirmation: work on a topic branch created from the latest `origin/main` (or the existing topic branch for that work; never commit on `main`), pass the verification commands, then `git commit`, `git push` the topic branch, and open a PR with `gh pr create` if none exists. If the branch already has an open PR, push to it and update the PR description when it has become stale.
- **Never merge**: AI agents **MUST NEVER** merge PRs (including enabling auto-merge with `gh pr merge --auto`), execute `git merge` into `main`, or push to `main`. Merging rests strictly with the human maintainer.
- **NEVER PROPOSE COMMITS OR PUSHES UNPROMPTED**: AI agents **MUST NEVER** prompt the user to commit or push, nor propose commit messages unprompted. When instructed by the user or when creating/updating pull requests on topic branches, agents may execute `git commit` and `git push` directly without seeking confirmation.
- **Verification Before Submitting**: All changes must pass the commands in [Section 3](#3-verification-commands).
- **Conventional Commits**: Use conventional commit prefixes (`feat:`, `fix:`, `refactor:`, `docs:`, `build:`, `ci:`, `test:`). The PR title must follow the same format; `validate-pr-title` checks it.
- **No Issue Numbers in Commit Messages**: Do not include issue numbers (e.g. `(#5)` or `#5`) anywhere in a commit message, summary or body, or in a PR title. Squash merges copy every commit message into `main`, so a `Closes #5` in a commit body can close an issue the PR was never meant to close. Link issues only from the PR description with a closing keyword (e.g. `Closes #5`). The ` (#N)` suffix GitHub appends to a squash-merge summary is the one exception.
- **Explicit Milestone Assignment Only**: AI agents **MUST NEVER** attach or set GitHub Milestones on Pull Requests or Issues unless explicitly requested by the user.
- **Evidence First**: Base all answers and actions on actual file contents and command output. Never speculate or assume.
- **Non-Destructive**: Never perform irreversible actions (file deletions, hard resets, rewriting pushed history such as amending or rebasing pushed commits and force-pushing, pushing to `main`) without explicit user approval. Ordinary pushes of new commits to a topic branch don't need approval (see above).
- **Targeted Edits**: Make minimal, logical changes strictly necessary for the request. Do not modify unrelated files.
- **English-Only Documentation**: All repository documentation, code comments, commit messages, and PR descriptions must be written strictly in English.
- **No Session Links**: Do not include AI session URLs or other internal session identifiers (e.g. a `Claude-Session:` trailer) in commit messages, PR descriptions, issues, or comments. A `Co-Authored-By:` trailer is fine. Exception: if the user explicitly states the session is public and instructs the agent to include its URL, doing so is allowed.

______________________________________________________________________

## 3. Verification Commands

Run these inside the Nix development shell (`nix develop` or `direnv allow`). CI runs the same set.

| Task | Command | Description |
| :--- | :--- | :--- |
| **Check formatting** | `treefmt --fail-on-change` | Checks every language treefmt covers; `zig fmt --check .` checks Zig files only |
| **Build** | `zig build` | Builds the static library |
| **Run tests** | `zig build test` | Runs every unit test in `src/` |
| **Check the flake** | `nix flake check` | Runs the flake checks, including the treefmt check and the package build |

______________________________________________________________________

## 4. Coding Conventions

- **Comments**: Every public declaration has a `///` doc comment, and every file starts with a `//!` comment that says what it contains. Comments are in English.
- **Naming**:
  - `PascalCase` for types and for files imported as a struct (`Pitch`, `EqualTemperament`).
  - `camelCase` for functions and methods (`fromMidi`, `freq`).
  - `snake_case` for variables, parameters, struct fields and enum tags (`semitones_from_a4`, `.cs`).
  - Comptime type parameters are always a single uppercase character (e.g. `T`).
  - Error tags are `PascalCase` (`error.PitchOutOfRange`).
- **Tests**: Keep tests next to the code they cover, in the same file. Every file ends with `test { std.testing.refAllDecls(@This()); }`. A test that checks a numeric result states the expected value and how it was derived in a comment (e.g. `// C7 = 440 * 2^(27/12) = 2093.005 Hz`).
- **Validation**: Reject invalid input with an error instead of reaching undefined or panicking behavior, and never clamp silently (e.g. `add` returns `error.PitchOutOfRange`).

______________________________________________________________________

## 5. Status Assessment Workflow

When asked to check status, assess the situation, or understand workspace context:

1. **Local Git State**: Inspect working tree (`git status -s -b`) and recent commits (`git log -n 5 --oneline`).
1. **GitHub PRs**: Check PR status (`gh pr status`) and current PR details (`gh pr view`).
1. **GitHub Issues**: Check relevant open issues (`gh issue list --limit 5`).
1. **Environment Health**: Run the commands in [Section 3](#3-verification-commands).
1. **Synthesis**: Report a concise, structured status covering local state, remote GitHub state, and environment health.
