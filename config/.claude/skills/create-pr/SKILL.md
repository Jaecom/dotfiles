---
name: cpr
description: Commit changes grouped by feature, push, and create a draft pull request
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash(git _), Bash(gh pr _)
---

# Create Pull Request

You are creating a pull request. Execute all steps without asking for confirmation. Be fully autonomous — the ONLY exception is when you need to create a new branch (user is on main/dev with uncommitted changes). In that case, suggest a branch name and ask the user to confirm before creating it. Everything else (commits, push, PR) should proceed without stopping.

## Step 1: Branch Check and Base Detection

- Detect the default branch: run `git remote show origin | grep 'HEAD branch'` and store the result as `<base>`. Use this consistently for all subsequent steps.
- Run `git branch --show-current` to get the current branch name.
- If on `main` or `dev`:
  - Run `git status` to check for uncommitted changes.
  - If there are **no uncommitted changes**, STOP and tell the user there is nothing to commit or push.
  - If there **are uncommitted changes**:
    - Run `git diff` and `git diff --staged` to review all changes (this review carries into Step 2 — do not re-run diffs).
    - Analyze the changes and suggest a branch name using the convention `feat/`, `fix/`, `refactor/`, `chore/`, etc. (e.g., `feat/add-user-auth`, `fix/login-redirect`).
    - **Ask the user to confirm or provide an alternative branch name.** This is the only interactive step.
    - Once confirmed, create and switch to the new branch: `git checkout -b <branch-name>`.
- If already on a feature branch:
  - Run `git log <base>..HEAD --oneline` to understand what commits already exist on this branch.
  - Run `git diff <base>...HEAD` to check if the branch has any changes vs base. If there are no commits and no uncommitted changes, STOP and tell the user there is nothing to push.

## Step 2: Review and Commit Unstaged/Staged Changes

- Run `git status` to check for uncommitted changes.
- If there are no changes, skip to Step 3.
- If diffs were already reviewed in Step 1 (branch creation path), reuse that analysis. Otherwise, run `git diff` and `git diff --staged`.
- **Group related changes by feature/purpose** into separate commits:
  - Analyze which files are related (e.g., a component and its styles, a service and its types).
  - Stage each group with `git add <specific files>` — never use `git add .` or `git add -A`.
  - Commit each group with a descriptive conventional commit message (e.g., `feat:`, `fix:`, `refactor:`, `docs:`, `style:`, `chore:`).
- Do NOT ask for confirmation. Just commit.

## Step 3: Push to Remote

- Run `git push -u origin HEAD` to push the branch.
- If the push fails due to diverged history, try `git pull --rebase origin HEAD` and then push again.
- If the push still fails, inform the user with the specific error and do not proceed.

## Step 4: Create Draft Pull Request

- Check if a PR already exists for this branch: `gh pr view --json url 2>/dev/null`. If a PR exists, show the user the existing PR URL and STOP — do not create a duplicate.
- Analyze ALL commits on this branch (from `git log <base>..HEAD`) and the full diff (`git diff <base>...HEAD`) to understand the complete set of changes.
- Determine if there are frontend changes by checking if any modified files match: `*.tsx`, `*.jsx`, `*.css`, `*.scss`, `*.html`, `*.svg`, or files under common UI directories.
- Generate the PR body using this format:

## Summary

  <one-line description of what this PR accomplishes>

## Key Changes

### <Category Name>

- change description
- change description

### <Category Name>

- change description

- If frontend/UI changes are detected, append:

## Images

  <!-- Add screenshots or screen recordings of UI changes -->

- Create the PR as a **draft** targeting `<base>` (draft because the user will review before marking ready):
  `gh pr create --draft --base <base> --title "<short title>" --body "<generated body>"`

- Show the user the PR URL when done.
