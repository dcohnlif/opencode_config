---
description: Create a detailed commit message and push to main.
---
# Commit and Push Workflow

1. **Analyze Current State**:
   - Run `git status` and `git diff`.
   - Run `git log -3 --oneline` to match the local project style.

2. **Stage Changes**:
   - `git add -A`. 
   - *Note: OpenCode's global 'ask' permission for `.env` files will automatically prevent these from being staged without your confirmation.*

3. **Generate Message**:
   - Ask yourself (Claude 4.6): "Based on the diff and our conversation history, determine the `<type>` (feat, fix, refactor, etc.) and write a detailed commit message."
   - Ensure you include these footers:
      - `Co-Authored-By: Claude <noreply@anthropic.com>`

4. **Execute Commit**:
   - Run: `git commit -m "[Generated Message]"` 

5. **Push to Main**:
   - Check branch: `git branch --show-current`.
   - If current branch is `main`, run `git push origin main`.
   - If not on `main`, stop and ask for permission.

6. **Verify**:
   - Run `git log -1` and show me the hash.
