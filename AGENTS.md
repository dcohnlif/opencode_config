# Global Rules

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
