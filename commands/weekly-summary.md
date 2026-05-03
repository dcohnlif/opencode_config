---
description: Summarize this week's OpenCode activity across tracked projects
---

# Weekly Summary

Generate a concise bulleted summary of what I worked on **over the last 7 days**, by querying the OpenCode session database.

## Instructions

**Database**: `~/.local/share/opencode/opencode.db` (SQLite)

### Step 1 — Find matching projects

Run this query to get the project IDs and names for the repos I care about:

```sql
SELECT id, name, worktree FROM project
WHERE worktree LIKE '%workflow-validation%'
   OR worktree LIKE '%workflow-insights%'
   OR worktree LIKE '%rhoai%';
```

### Step 2 — Find this week's sessions

Query sessions that were **active this week** — use `time_updated` (not `time_created`) so that multi-day sessions are included. Use `strftime('%s','now','-7 days','start of day') * 1000` as the epoch-ms threshold. Exclude subagent sessions (`parent_id IS NOT NULL`).

```sql
SELECT s.id, s.title, s.summary_files, s.summary_additions, s.summary_deletions,
       p.name AS project_name, p.worktree,
       (SELECT COUNT(*) FROM message m WHERE m.session_id = s.id) AS msg_count,
       CASE WHEN EXISTS (
         SELECT 1 FROM part pt
         JOIN message m ON pt.message_id = m.id
         WHERE m.session_id = s.id
           AND json_extract(pt.data, '$.type') = 'text'
           AND json_extract(pt.data, '$.text') LIKE '%# Auto-Dev%'
       ) THEN 1 ELSE 0 END AS is_auto_dev
FROM session s
JOIN project p ON s.project_id = p.id
WHERE p.id IN (<project_ids_from_step_1>)
  AND s.time_updated >= (strftime('%s','now','-7 days','start of day') * 1000)
  AND s.parent_id IS NULL
ORDER BY p.name, s.time_updated;
```

If no sessions are found, output: **"No activity found for this week."** and stop.

### Step 3 — Gather context for each session

For each session, collect:

1. **First user message text** — this is the task/request that started the session:
```sql
SELECT json_extract(pt.data, '$.text') AS user_text
FROM part pt
JOIN message m ON pt.message_id = m.id
WHERE m.session_id = '<session_id>'
  AND json_extract(m.data, '$.role') = 'user'
  AND json_extract(pt.data, '$.type') = 'text'
ORDER BY m.time_created ASC, pt.time_created ASC
LIMIT 1;
```

2. **Todo items** — these track what was actually accomplished:
```sql
SELECT content, status FROM todo
WHERE session_id = '<session_id>'
ORDER BY position;
```

Batch these queries efficiently — combine multiple session IDs into single queries where possible to minimize bash calls.

### Step 4 — Weigh and prioritize sessions

Not all sessions are equal. Rank sessions by importance using these signals (highest priority first):

1. **`/auto-dev` or `/parliament` sessions** (`is_auto_dev = 1`) — these are structured development workflows that produced concrete code changes. They should always appear in the summary.
2. **High diff stats** — sessions with many files changed / lines added are substantive implementations.
3. **High message count** — long sessions indicate deep work on a topic.
4. **Sessions with completed todo items** — tracked task completion signals real deliverables.
5. **Exploration / Q&A sessions** — sessions with zero diffs and few messages are lower priority. Include them only if they covered a meaningful topic, and place them at the end.

### Step 5 — Synthesize the summary

Using the session titles, first user messages, todo items, diff stats, and priority weights, produce a bulleted summary with these rules:

- **Group by project** — use the project `name` as the heading (if the name is empty, derive a short name from the `worktree` path)
- **Deduplicate aggressively** — a week of work will have many sessions. Merge related sessions into single bullets. For example, 5 sessions about "RCA improvements" become one bullet: "Improved RCA flow for test failure analysis".
- **Order within each project** — high-weight items first (features, implementations, bug fixes), then investigations/explorations last
- **Prioritize outcomes** — lead with features shipped, bugs fixed, concrete deliverables. Put investigations/explorations at the end.
- **Style** — past tense, action-oriented, concise (one line per bullet). No session IDs, no timestamps, no diff numbers.
- **Substance** — focus on *what was accomplished*, not process details like "explored code" or "ran queries". If sessions were purely exploratory Q&A with no concrete outcome, summarize the topic investigated.
- **Length** — aim for 3-8 bullets per project. If a project has very little activity, a single bullet is fine.

### Output format

```
**<project-name>**
- Did X
- Fixed Y
- Investigated Z

**<other-project>**
- Implemented A
- Refactored B
```

Do NOT include any explanation, preamble, or sign-off. Output only the bulleted summary.
