---
name: cc
description: Interactive git workflow — commit, push, and merge with step-by-step prompts
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash(git *), AskUserQuestion
---

# Create Commit

You are running an interactive git workflow. First gather info, then ask all questions at once, then execute everything.

## Phase 1: Gather Info (automatic, no prompts)

Run all of these in parallel:
- `git status`
- `git diff`
- `git diff --staged`
- `git log --oneline -10`
- `git branch --show-current`
- `git remote show origin | grep 'HEAD branch'`
- `git branch -r`

If there are no changes at all, STOP and tell the user there is nothing to commit.

## Phase 2: Ask All Questions (single AskUserQuestion call)

**CRITICAL:** Use exactly **one `AskUserQuestion` call** with all questions combined into the `questions` array. Do NOT call `AskUserQuestion` multiple times. This gives the user a tabbed interface where they can navigate between questions before confirming.

Build 2-3 questions (depending on context) with these headers and options:

### Question 1 — header: `"Branch"`

- **If on a feature branch** (not `main`, `master`, `dev`, `develop`):
  - Option 1: `Stay on <current>` — mark as **(Recommended)**
  - Options 2-3: Generate 2 alternative branch names based on the changes (using `feat/`, `fix/`, `refactor/`, `chore/` convention)
- **If on a default/shared branch** (`main`, `master`, `dev`, `develop`):
  - Options 1-2: Generate 2-3 branch names based on the changes (first is **(Recommended)**)
  - Last option: `Stay on <current>`

### Question 2 — header: `"Push"`

- Option 1: `Push to origin` **(Recommended)**
- Option 2: `Skip`

### Question 3 — header: `"Merge"`

Only include this question if the user is on (or will be on) a non-default branch. Detect available target branches from `git branch -r` (look for `main`, `master`, `dev`, `develop`, `sandbox`, `staging`).

- One option per available target branch (e.g., `Merge into main`, `Merge into dev`)
- The default branch option is **(Recommended)**
- Last option: `Skip`

If the user will stay on the default branch (from Question 1), omit this question entirely.

## Phase 3: Execute (automatic, no prompts)

Execute everything based on the user's answers, in order:

### 3a: Branch
- If a new branch was chosen: `git checkout -b <branch-name>`

### 3b: Stage & Commit
- Group related changes by feature/purpose.
- Stage with `git add <specific files>` — never use `git add .` or `git add -A`.
- Write commit messages using **Conventional Commits** format:

```
<type>: <short summary>
```

#### Commit rules

- **No parenthesized scopes.** Write `feat: add storage layer` NOT `feat(storage): add storage layer`.
- **Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `ci`, `build`, `revert`
- **Summary:** imperative mood, lowercase, no period, under 72 characters.
- No description/body in the commit message.
- Add `BREAKING CHANGE:` footer if applicable.
- Create the commit using a HEREDOC for the message.
- If changes span multiple unrelated concerns, create multiple focused commits (repeat stage + commit for each group).

### 3c: Push
- If user chose Push: `git push -u origin HEAD`
- If user chose Skip: skip push. Also skip merge regardless of merge answer.

### 3d: Merge
- Only if push happened AND merge target was selected (not Skip).
- `git checkout <target> && git merge <feature-branch> && git push origin <target>`
- Switch back to the feature branch: `git checkout <feature-branch>`

## Phase 4: Summary

Show a concise summary of what was done:
- What was committed (files, message)
- Whether it was pushed
- Whether it was merged (and into which branch)
