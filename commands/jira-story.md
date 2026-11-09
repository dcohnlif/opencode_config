---
description: Create a Jira Story in RHAI, assigned to you, and add it to the current sprint by default.
---

# Create Jira Story

This command creates a Story in the RHAI project based on the user's description. It writes a detailed summary and description, assigns it, and adds it to the current sprint by default. If the user specifies a team, preserve that team and use the next sprint.

## Configuration

- **Project**: RHAI
- **Board ID**: 3723
- **Issue Type**: Story
- **Default Assignee**: dcohnlif@redhat.com (David Cohn Lifshitz)
- **Default Priority**: Normal (the valid standard priority in RHAI)
- **Sprint Field**: customfield_10020
- **Team Field**: customfield_10001
- **Team ID**: 702f36f3-00b7-4faf-b734-ea1b6fb6d097 (Yoni's Team)

## User Input

```text
$ARGUMENTS
```

## Instructions

1. **Parse the Request**: Read the user's input. The input describes what they want to do. If they mention an assignee (e.g., "assign to jsmith"), use that person instead of the default. Otherwise, assign to `dcohnlif@redhat.com`.

2. **Craft the Summary**: Write a clear, concise summary (one line, max ~80 chars) that captures the essence of the request. Use imperative mood (e.g., "Add pagination to dashboard API", "Fix race condition in auth middleware").

3. **Craft the Description**: Write a detailed Markdown description that includes:
   - **Context**: Why this work is needed.
   - **Scope**: What specifically needs to be done.
   - **Acceptance Criteria**: A checklist of conditions that must be met for this story to be considered complete.
   - **Notes**: Any relevant technical considerations or constraints.

4. **Find the Sprint**: Use board `3723`. If the user did not specify a team, find the `active` sprint; if none exists, use the next `future` sprint. If the user specified a team, find the next `future` sprint; if none exists, use the `active` sprint.

5. **Create the Issue**: Use the `atlassian_jira_create_issue` tool with:
   - `project_key`: `RHAI`
   - `summary`: The crafted summary
   - `issue_type`: `Story`
   - `assignee`: The assignee email (default: `dcohnlif@redhat.com`)
   - `description`: The crafted description
   - `additional_fields`: `{"priority": {"name": "Normal"}, "customfield_10001": "702f36f3-00b7-4faf-b734-ea1b6fb6d097"}` when no team is specified; if the user specifies a team, preserve it and use its team ID.

6. **Add the issue to the sprint**: After creation, use `atlassian_jira_add_issues_to_sprint` with the new issue key and the sprint ID found in step 4. The Jira connector does not accept the Sprint field in the create request.

   Pass the sprint ID returned in step 4 as a string to `atlassian_jira_add_issues_to_sprint`.

7. **Report**: Output the created issue key, summary, assignee, sprint name, and a direct link:
   ```
   Created: RHAI-XXXXX
   Summary: [summary]
   Assignee: [name]
   Sprint: [sprint name]
   Link: https://redhat.atlassian.net/browse/RHAI-XXXXX
   ```
