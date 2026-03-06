---
name: och
description: Open all changed and new files in VS Code
user-invocable: true
allowed-tools: Bash(code *), Bash(git diff *), Bash(git ls-files *)
---

# Open Changed

Open all git-modified (staged/unstaged) and untracked files in VS Code.

Run this command without asking for confirmation:

```
(git diff --name-only HEAD --diff-filter=d; git ls-files --others --exclude-standard) | xargs code
```

If there are no files to open, tell the user there are no changed or new files.
