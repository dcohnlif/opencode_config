---
description: Create a detailed commit message and commit. For GitLab repos, ask before pushing.
---
# Commit Workflow

1. **Detect Remote Type**:
   - Run `git remote get-url origin`.
   - If the URL contains `gitlab`, set `IS_GITLAB=true`.
   - If the URL contains `github`, set `IS_GITLAB=false`.

2. **Analyze Current State**:
   - Run `git status` and `git diff`.
   - Run `git log -3 --oneline` to match the local project style.

3. **Stage Changes**:
   - `git add -A`. 
   - *Note: OpenCode's global 'ask' permission for `.env` files will automatically prevent these from being staged without your confirmation.*

4. **Generate Message**:
   - Ask yourself (Claude 4.6): "Based on the diff and our conversation history, determine the `<type>` (feat, fix, refactor, etc.) and write a detailed commit message."
   - Ensure you include these footers:
      - `Co-Authored-By: Claude <noreply@anthropic.com>`

5. **Execute Commit**:
   - Run: `git commit -m "[Generated Message]"` 

6. **Post-Commit Summary**:
   - Run `git status` to show any remaining uncommitted changes in the repo.
   - Run `git log -1` and show the commit hash.

7. **Push**:
   - If `IS_GITLAB=false` (GitHub):
     - Check branch: `git branch --show-current`.
     - If current branch is `main`, run `git push origin main`.
     - If not on `main`, stop and ask for permission.
   - If `IS_GITLAB=true` (GitLab):
     - Do NOT push automatically.
     - Ask the user: "Do you want me to push these commits and create a merge request?"
     - Only push if the user confirms. Push to a feature branch and create an MR.
