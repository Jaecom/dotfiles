---
name: cc
description: Create a well-structured conventional commit from staged/unstaged changes
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash(git *), AskUserQuestion
---

# Create Commit

You are creating a commit. Execute all steps without asking for confirmation unless explicitly noted.

## Step 1: Assess Changes

- Run `git status`, `git diff`, and `git diff --staged` to understand all changes.
- Run `git log --oneline -10` to see recent commit style for reference.
- If there are no changes at all, STOP and tell the user there is nothing to commit.

## Step 2: Branch Check

- Run `git branch --show-current` to get the current branch.
- Detect the default branch: `git remote show origin | grep 'HEAD branch'` — store as `<default>`.
- **Create a new branch if either condition is true:**
  1. Currently on a default/shared branch (`main`, `master`, `dev`, `develop`).
  2. The current changes are clearly unrelated to the current branch name (e.g., branch is `fix/login-bug` but changes are adding a new payments feature).
- If a new branch is needed:
  - Analyze the changes and generate 2-3 candidate branch names using the `feat/`, `fix/`, `refactor/`, `chore/` convention.
  - **Use the `AskUserQuestion` tool** to present the branch name options as selectable choices (the user can also pick "Other" to type a custom name). Put the recommended option first with "(Recommended)" in the label. Use header "Branch" and phrase the question as "Which branch name would you like to use?".
  - Create and switch: `git checkout -b <branch-name>`.
- If the current branch is appropriate for the changes, continue.

## Step 3: Stage Changes

- If there are already staged changes and no unstaged changes, skip to Step 4.
- If there are unstaged changes, stage them intelligently:
  - **Group related changes** by feature/purpose into separate commits if the changes span multiple unrelated concerns.
  - Stage with `git add <specific files>` — never use `git add .` or `git add -A`.
  - If ALL changes are related to a single concern, stage everything together.

## Step 4: Write Commit Message

Use **Conventional Commits** format WITHOUT parenthesized scopes:

```
<type>: <short summary>
```

### Rules

- **No parenthesized scopes.** Write `feat: add storage layer` NOT `feat(storage): add storage layer`.
- **Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `ci`, `build`, `revert`
- **Summary:** imperative mood, lowercase, no period, under 72 characters.
- Do not create a description for the commit message
- Add `BREAKING CHANGE:` footer if applicable.

### Examples

```
feat: add user authentication with JWT
```

```
fix: prevent duplicate form submissions
```

```
refactor: simplify database connection pooling

Replaced custom pool manager with built-in connection pooling
from the database driver, reducing code and fixing leak on timeout.
```

## Step 5: Commit

- Create the commit using a HEREDOC for the message.
- If changes span multiple unrelated concerns, create multiple focused commits (repeat Steps 3-4 for each group).
- Run `git status` after committing to verify success.
- Show the user a summary of what was committed.
