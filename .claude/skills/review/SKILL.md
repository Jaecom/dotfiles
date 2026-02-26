---
name: rv
description: Review staged/unstaged changes before pushing for side effects, breaking changes, and issues
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash(git diff*), Bash(git log*), Bash(git status)
---

# Pre-Push Code Review

Run `git diff` to see all staged and unstaged changes. Then read each changed file in full for context. For each change, review the following:

## 1. API & Backend Contract

- Do any changes alter API request/response payloads (field names, types, structure)?
- Are there new, renamed, or removed fields that the backend expects?
- Will existing data in the database still be compatible with the new code?
- Are API changes backwards compatible? Can old clients still work?

## 2. Environment Behavior

- Trace the code path for each environment (development, sandbox, production)
- Verify correct API base URLs and credentials are used per environment
- Check that environment-specific logic (conditionals, guards) is correct

## 3. Side Effects & Blast Radius

- Do changes in shared utilities, types, or schemas affect other pages/components?
- Grep for all callers of modified functions — do they handle the new behavior?
- Do removed or renamed exports break other imports?
- Could this change affect other teams or services?

## 4. Error Handling & Resilience

- Can any new code path throw an unhandled error?
- Are queries/mutations guarded against undefined or missing data?
- Will failures crash the page or degrade gracefully?
- What happens under bad network conditions (timeout, 500, rate limit)?

## 5. Data Migration & Compatibility

- If field names changed, what happens to existing records with old field names?
- Will old data be silently ignored or cause errors?
- Is there a migration path or will data be orphaned?

## 6. Security

- Are auth tokens, API keys, or secrets exposed in logs, URLs, or client state?
- Is user input sanitized before rendering (XSS) or sending to APIs (injection)?
- Are there new endpoints or data flows that bypass existing auth checks?
- Do permissions and role checks still apply after the change?

## 7. Race Conditions & State

- Can async operations (fetches, mutations) fire with stale props or state?
- Are there missing loading/pending guards that could allow double submission?
- Could component unmounting during an in-flight request cause errors?
- Are optimistic updates consistent with server responses on failure?

## 8. Performance

- Are there unnecessary re-renders (missing memo, unstable references in deps)?
- Do new queries fire on every render or are they properly cached/debounced?
- Are large lists or objects being created inside render without memoization?
- Does this increase bundle size significantly (new dependencies)?

## 9. Type Safety

- Are there non-null assertions on values that could actually be undefined?
- Are there type casts that hide potential runtime errors?
- Do TypeScript types match the actual runtime data shape from the API?

## 10. Rollback Safety

- If this deploy fails, can it be reverted without data corruption?
- Are there irreversible side effects (schema changes, third-party calls)?
- Does the change require coordinated deploys with other services?

## Output Format

First, provide a brief summary of what the change does.

Then present all findings in a single table:

| # | Severity | Issue |
|---|----------|-------|
| 1 | **breaking** / **warning** / **info** | `file:line` — Description of the issue |

After the table, end with a **Verdict** line: whether the changes are safe to push, with a brief justification.

If no issues found, confirm the changes are safe to push.
