# Global Rules

## Model & Thinking Requirements

Always use the latest Claude model (currently Claude Opus 4.6) with maximum thinking enabled. The config must specify adaptive thinking (`"type": "adaptive"`) which gives the model full autonomy over its reasoning depth — this is the highest thinking mode available for Claude 4.6+. Both the primary agent and all subagents (including the auditor) must use this configuration. Do not downgrade models or reduce thinking to save cost or latency.

## Priority: Correctness Over Cost

I do not care about token cost, execution time, or convenience shortcuts. Always optimize for **robustness and correctness** above all else.

Specific expectations:

- Never take shortcuts to save tokens, time, or API calls.
- If a task requires exhaustive validation, do the exhaustive validation -- do not sample or approximate.
- If a thorough approach takes 5 minutes but a quick approach takes 1 minute, take the thorough approach.
- When generating code, prioritize correctness, explicit error handling, and defensive programming over brevity.
- When multiple implementation paths exist, choose the most robust one, not the easiest or cheapest.
- Do not summarize, truncate, or skip steps to reduce output length.
- Read all relevant files fully rather than skimming. Search thoroughly rather than guessing.
- When uncertain, investigate and verify rather than making assumptions.
- Use the most capable model/tool available for the task at hand, even if a cheaper alternative could "probably" work.

## Test Before Push

Whenever you build a new feature, fix a bug, or make any code change that will be pushed to git, always ask the user if they want to run/test the feature before pushing. Follow this flow:

1. Implement the change.
2. Ask the user: "Want me to run this to test it before pushing?"
3. If yes: run the feature or test command and show the results.
4. If the results are not as expected: fix the issue, re-run, and repeat until it works.
5. Only after the user confirms the results are correct (or the tests pass), proceed with committing and pushing.

This applies to all workflows -- direct prompts, `/push`, and any other code change flow. The `/parliament`, `/auto-dev`, and `/speckit-auto-dev` commands have their own built-in testing phases and are exempt from this rule.
