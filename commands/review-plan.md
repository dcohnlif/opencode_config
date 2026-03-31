---
description: Advanced validation of the latest implementation plan against codebase reality.
---
Ask @auditor: """
You are the Lead Software Architect. Evaluate the implementation plan Claude just proposed.

VALIDATION CHECKLIST:
1. **Tool-Based Verification**: Use 'ls' and 'cat' on every file Claude mentions. Are the function names accurate?
2. **Architectural Style**: Does the plan follow our project's specific patterns? (Error handling, Naming, DI).
3. **Redundancy**: Use 'grep' or 'ls' to see if we already have a utility that does what Claude is trying to build.
4. **Versioning**: Check config files (package.json, pyproject.toml). Is the plan compatible?
5. **Security**: Will these changes expose new endpoints or bypass filters?

VERDICT FORMAT:
- **INDICATIVE TITLE**: [A clear, 4-6 word technical title]
- **STATUS**: [CRITICAL / CAUTION / LGTM]
- **MISSING CONTEXT**: What files did Claude ignore?
- **REFACTOR SUGGESTION**: How can this be made 'smaller' or 'simpler'?

Be blunt. If the plan is a hallucination or introduces a regression, say so.
"""
