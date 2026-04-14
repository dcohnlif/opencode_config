---
description: Create a Jira Story in AIPCC project, assigned to you, added to the next sprint.
---

# Create Jira Story

This command creates a Story in the AIPCC project based on the user's description. It writes a detailed summary and description, assigns it, and adds it to the next sprint on the team's scrum board.

## Configuration

- **Project**: AIPCC
- **Board ID**: 3723
- **Issue Type**: Story
- **Default Assignee**: dcohnlif@redhat.com (David Cohn Lifshitz)
- **Default Priority**: Medium
- **Sprint Field**: customfield_10020

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

4. **Find the Next Sprint**: Use the `atlassian_jira_get_sprints_from_board` tool with board_id `3723` and state `future` to find the next sprint. If no future sprint exists, check for the `active` sprint instead.

5. **Create the Issue**: Use the `atlassian_jira_create_issue` tool with:
   - `project_key`: `AIPCC`
   - `summary`: The crafted summary
   - `issue_type`: `Story`
   - `assignee`: The assignee email (default: `dcohnlif@redhat.com`)
   - `description`: The crafted description
   - `additional_fields`: `{"priority": {"name": "Medium"}, "customfield_10020": {"id": <sprint_id>}}`

   Where `<sprint_id>` is the numeric ID of the next sprint found in step 4, passed as an integer (not a string).

6. **Report**: Output the created issue key, summary, assignee, sprint name, and a direct link:
   ```
   Created: AIPCC-XXXXX
   Summary: [summary]
   Assignee: [name]
   Sprint: [sprint name]
   Link: https://redhat.atlassian.net/browse/AIPCC-XXXXX
   ```
