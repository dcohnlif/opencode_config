# General Learnings (accumulated across projects)

## AI-Driven Test Spec Generation
- **Single-document specs beat multi-file specs** — an LLM performer treats separate task files as disconnected tests. One document with inline steps produces connected narratives where state flows between steps (shared project, shared resources, progressive verification).
- **Specs must follow documentation, not the UI** — if the UI differs from docs, that's a finding to surface, not something to fix in the spec. Silently correcting specs to match the UI hides real docs-vs-UI bugs.
- **Terminology mappings correct LLM training data, not docs-vs-UI gaps** — the LLM's training data is a stale snapshot. Mappings prevent it from hallucinating old terms when the docs already use the correct ones.
- **Inject correct terms INTO the prompt, not just as post-processing** — LLMs ignore context in favor of training data for common terms. The prompt must explicitly say "YOUR TRAINING DATA IS WRONG FOR THIS VERSION — use ONLY the documentation provided."
- **Generate tasks individually, not all-in-one** — large output (50K+ tokens) times out. Per-task generation (~1-2K output each) produces better quality and avoids timeouts.
- **Feedback loop: generate → audit terminology → review → correct → repeat** — catches issues the LLM introduces despite grounding. Max 2 attempts to avoid infinite loops.
- **Every improvisation is a spec defect** — if the performer deviates from the spec, the spec is wrong. Zero tolerance. Catalogue every improvisation with: what the spec said, what the UI showed, the specific fix needed.

## Autonomous Test Execution (LLM Performer)
- **The performer is browser-only** — never include CLI commands (`oc`, `kubectl`, `curl`) in specs intended for a Playwright-based performer. If a feature requires CLI, describe it as a prerequisite and verify its effects through the UI.
- **The performer may override spec instructions based on semantic interpretation** — e.g., seeing "DataScienceCluster" in a task title and deciding to use cluster-admin credentials despite the spec saying otherwise. File bugs for this behavior.
- **Stale task files silently override updated specs** — if `tasks/` exists alongside `spec.md`, the performer reads the tasks, not the spec. Always clean up old artifacts before re-running.
- **Password leakage in action logs** — Playwright action loggers capture form field values during login. Redaction regex must handle nested selectors like `getByRole('textbox', { name: 'Password' })`. Simple `[^)]*` regex breaks on nested parentheses.

## QE Artifact Review
- **Scan for secrets in every artifact** — action logs leak passwords through form field capture. Cross-reference against actual `.env` values.
- **Cross-reference task count in results vs spec** — a "COMPLETE" with fewer tasks than the spec defines is a false pass.
- **Distinguish root causes: product defect vs spec error vs environment gap vs performer error** — most "failures" are environment gaps (wrong model format, missing hardware profile, unconfigured operator), not product bugs.
- **The action log is forensic evidence** — reconstruct minute-by-minute failure timelines from timestamps, actions, and page transitions.
- **Decompose failures into chains** — a single user-visible failure is almost never one bug. Look for: missing validation → misleading error → no recovery path. Each link is a separate defect with independent severity.

## MCP Tool Reliability
- **MCP servers don't auto-reconnect mid-session** — if you kill the process, you need to restart OpenCode entirely. The tool list is frozen at session start.
- **Search paths may exclude content** — verify that MCP tools search all relevant directories. Documentation repos often have `upstream/` modules alongside top-level `modules/` — a path filter of `modules/` misses the upstream content.
- **Git grep regex pitfalls** — Python rf-strings with escaped quotes produce `\x27` instead of literal `'`. Use simple string matching when possible. Also, `[` in regex is interpreted as a character class — escape it or use fixed-string search.
- **Different attribute names across source trees** — upstream modules may use different metadata attributes (e.g., `:_module-type: PROCEDURE` vs `:_mod-docs-content-type: PROCEDURE`). Search for both.

## Infrastructure & Environment
- **Model format matters for serving runtimes** — vLLM needs transformer LLMs (GPT-2, Llama, Granite), not CNN models (ResNet, VGG). A wrong model in S3 causes deployments to hang silently at "Starting/Pending" with no error message.
- **Hardware profiles gate model deployment** — vLLM needs 8+ GiB memory. A default profile with 4 GiB causes silent hangs, not an error. The spec should include fail-stop instructions for insufficient profiles.
- **Cluster DNS can be transiently unreliable** — dashboard loading failures may be DNS or ingress, not the dashboard itself. Always verify with `curl` before blaming the product.
- **Duplicate env vars cause confusion** — standardize on one naming convention (e.g., `AWS_*` vs `S3_*`). Document which vars are required, which are runtime config, and which are unused.
- **"Resolved" in Jira doesn't mean "deployed"** — always verify on the actual cluster that a fix is deployed before removing blockers from specs.
