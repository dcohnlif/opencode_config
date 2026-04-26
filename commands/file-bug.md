---
description: File a product/documentation bug in RHOAIENG after a journey run failure. Verifies the defect, gathers evidence, checks for duplicates, and creates a thorough Jira bug.
---

# File Product Bug

This command is invoked MANUALLY after a workflow-validation-director journey run has FAILED and the user believes the failure is caused by a product or documentation defect. The command verifies the defect is real, gathers cluster evidence, searches for duplicates, and files a thorough bug in the RHOAIENG Jira project.

**CRITICAL**: This command must NEVER be run automatically. The user explicitly triggers it after reviewing a failed run.

## Input

The user provides the path to the failed run's artifacts directory:

```text
$ARGUMENTS
```

This path should point to a directory like:
`/home/dcohnlif/GIT/workflow-validation-director/artifacts_journeys/<date>/<workflow-name>`

containing `results.txt`, `report.md`, `log.md`, `actions.md`, and optionally screenshots (`.png`).

## Configuration

- **Project**: RHOAIENG
- **Issue Type**: Bug
- **Default Priority**: Medium
- **Reporter**: Workflow Validation (workflow-validation@redhat.com) -- set via post-creation update
- **Director .env**: /home/dcohnlif/GIT/workflow-validation-director/.env
- **Journey specs**: /home/dcohnlif/GIT/workflow-insights/data/journeys/

## ABSOLUTE RULES

1. **NEVER attach or include secrets** in the bug description, logs, or attachments. Before attaching any file or including any log output, scan for and redact: passwords, tokens, API keys, bearer tokens, secret keys, connection strings, credentials, certificates, private keys, `.env` file contents. If a log line contains any of these, redact the sensitive value with `[REDACTED]`. If you are unsure whether content contains secrets, do NOT include it.

2. **NEVER file a bug without verifying it first.** Phase 2 is a hard gate. If you cannot confirm the issue is a real product/documentation defect, STOP and tell the user.

3. **The description format (Phase 8) is non-negotiable.** Every bug MUST have: Versions, Setup/Scenario, Steps to Reproduce, Expected Result, Actual Result. No exceptions.

---

## Phase 1: Read and Understand the Failure

1. Read these files from the artifacts directory:
   - `results.txt` -- pass/fail summary per task
   - `report.md` -- detailed report with issues and observations
   - `log.md` -- timestamped observation log
   - `actions.md` -- browser action timeline

2. Derive the workflow/journey name from the directory name (last path component).

3. Read the journey spec from `/home/dcohnlif/GIT/workflow-insights/data/journeys/<workflow-name>/spec.md`.

4. Identify:
   - Which task(s) failed
   - What was expected (per the spec)
   - What actually happened (per the report/log)
   - Whether the performer had to improvise (and why)
   - Any "Documentation Issues" or "Improvisation Required" sections in the report

---

## Phase 1.5: Check Bug History (Prevent Duplicates)

Before proceeding with full analysis, check whether this failure has been seen before.

1. **Read history file**: Read `.file-bug/history.json` from the workspace root (typically `/home/dcohnlif/GIT/workflow-validation-director/.file-bug/history.json`). If the file doesn't exist, skip this phase and proceed to Phase 2.

2. **Extract failure signature**: From the artifacts read in Phase 1, build a failure signature:
   - Journey/workflow name
   - Failed task name(s)
   - Error message or key failure text (first 200 chars)

3. **Match against history**: Compare the failure signature against all entries in `history.json`. A match is when the same journey + same task + similar error text (fuzzy match, >80% overlap) has been filed before.

4. **If a match is found**:
   - Show the user the previous bug:
     > "This failure matches a previously filed bug:
     > RHOAIENG-XXXXX: [summary] (Status: [status], Filed: [date])
     > Journey: [journey], Task: [task]
     >
     > Options:
     > 1. Add a comment to the existing bug noting this recurrence
     > 2. File a new bug anyway (e.g., if the fix was supposed to resolve this)
     > 3. Skip — do not file anything"
   - Follow the user's choice. If option 1, use `atlassian_jira_add_comment` to add a comment to the existing bug noting the date and run, then skip to Phase 12.

5. **If no match**: Proceed to Phase 2.

---

## Phase 2: Verify This Is a Real Product/Documentation Bug (HARD GATE)

This is the most important phase. Do NOT skip it.

1. Read `/home/dcohnlif/GIT/workflow-validation-director/.env` to get `TEST_DASHBOARD_URL`, `ADMIN_USER`, `ADMIN_PASSWORD`, and cluster API URL (derive from the dashboard URL: replace `rh-ai.apps.` with `api.` and append `:6443`).

2. Log into the cluster:
   ```
   oc login <api-url> -u <admin-user> -p '<admin-password>' --insecure-skip-tls-verify
   ```

3. **For UI/functional bugs**: Verify the cluster state matches the failure:
   - Check the relevant Custom Resources (`odhdashboardconfig`, `notebook`, `inferenceservice`, etc.)
   - Check pod status, events, and logs for the affected component
   - Verify the setting/resource that failed actually has the value the performer reported
   - Example: if PVC size didn't persist, run `oc get odhdashboardconfig -n redhat-ods-applications -o jsonpath='{.items[0].spec.notebookController.pvcSize}'`

4. **For documentation bugs**: Query the RHOAI documentation MCP tools:
   - Use `rhoai-docs_search_documentation` to find what the docs say about the feature
   - Use `rhoai-docs_read_procedure` to read the exact documented procedure
   - Verify the spec followed the documentation correctly
   - Verify the product UI differs from what the docs describe

5. **For UI/functional bugs -- Playwright Reproduction**: If the bug involves UI behavior (dashboard pages, forms, buttons, navigation), attempt to reproduce it live using Playwright browser tools and the cluster credentials from the `.env` file:
   a. Navigate to `TEST_DASHBOARD_URL` from the `.env` file.
   b. Log in using `ADMIN_USER` and `ADMIN_PASSWORD` from the `.env` file.
   c. Follow the same steps described in the failure report to reproduce the bug.
   d. Take a screenshot of the reproduced bug state using `playwright_browser_take_screenshot`.
   e. Capture a DOM snapshot of the failure state using `playwright_browser_snapshot` (save to file) and `playwright_browser_evaluate` with `() => document.documentElement.outerHTML` (save the raw HTML to `.file-bug/dom_snapshot.html` in the workspace root). This gives developers the exact DOM state at the time of failure.
   f. If the bug reproduces: this is strong evidence. Save the screenshot and DOM snapshot for attachment in Phase 11.
   g. If the bug does NOT reproduce: do NOT open the bug. Instead, STOP and present the user with:
      > "The UI bug could not be reproduced via Playwright on the live cluster. This may indicate:
      > - The issue was transient (timing, network, caching)
      > - The issue has already been fixed in a recent deployment
      > - The original failure was caused by the automation performer's interaction pattern rather than a product defect
      >
      > Suggestions:
      > 1. Re-run the journey to see if the failure recurs
      > 2. Try to reproduce manually in a browser to rule out automation artifacts
      > 3. Check if the cluster/operator was recently updated since the failed run
      > 4. If you still believe this is a real bug, describe what you observed and I can file it with a note that automated reproduction failed"
      
      Only proceed if the user explicitly asks to file it anyway.

6. **For documentation/UI mismatch bugs -- Version-Matched Doc Verification**: If the failure report indicates a mismatch between the product UI and the documentation:
   a. Read `RHOAI_VERSION` from the `.env` file at `/home/dcohnlif/GIT/workflow-validation-director/.env`. This is the version that was being tested.
   b. Use `rhoai-docs_list_doc_versions` to find available doc versions.
   c. Use the doc version that matches the `RHOAI_VERSION` from the `.env` file (e.g., if `RHOAI_VERSION=2.19`, use version `2.19`). If an exact match is not available, use the closest lower version.
   d. Use `rhoai-docs_search_documentation` with the matching version to find what the docs say about the feature.
   e. Use `rhoai-docs_read_procedure` with the matching version to read the exact documented procedure.
   f. Compare the documented behavior against the actual product UI (use Playwright to verify the live UI state if needed).
   g. **Classification decision**:
      - If the docs are wrong but the product is correct → file as **Documentation bug** with component **Documentation**.
      - If the product is wrong but the docs are correct → file as a **product bug** with the appropriate component.
      - If both are wrong → file two bugs (one Documentation, one product).

7. **DECISION GATE**:
   - If the issue IS a product/documentation bug: proceed to Phase 3.
   - If the issue is NOT a bug (spec error, infrastructure issue, test environment problem, performer error): STOP and tell the user:
     > "This does not appear to be a product bug. It looks like [explanation]. The failure was caused by [reason]. Do you still want to file it?"
   - Only proceed if the user explicitly confirms.

---

## Phase 3: Gather Cluster Versions

Run these commands and record the output:

```bash
# OCP version
oc get clusterversion -o jsonpath='{.items[0].status.desired.version}'

# RHOAI version (from CSV)
oc get csv -n redhat-ods-operator -o jsonpath='{.items[0].spec.version}'

# RHOAI release version (from DSCI status — may differ from CSV in pre-release)
oc get dsci -A -o jsonpath='{.items[0].status.release.version}'

# RHOAI operator status
oc get dsci -A -o jsonpath='{.items[0].status.phase}'

# Dashboard route
oc get route -n redhat-ods-applications -l app=odh-dashboard -o jsonpath='{.items[0].spec.host}'

# RHOAI operator build date (createdAt from CSV)
oc get csv -n redhat-ods-operator rhods-operator.$(oc get csv -n redhat-ods-operator -o jsonpath='{.items[0].spec.version}') -o jsonpath='{.metadata.annotations.createdAt}' 2>/dev/null || echo "N/A"

# DSC managed component versions (from DataScienceCluster status)
oc get datasciencecluster -o json | python3 -c "
import json, sys
dsc = json.load(sys.stdin)['items'][0]['status']['components']
for name, info in sorted(dsc.items()):
    state = info.get('managementState', 'Unknown')
    releases = info.get('releases', [])
    if releases:
        for r in releases:
            print(f\"{name}: {r['name']} {r['version']} ({state})\"  )
    else:
        print(f\"{name}: ({state})\"  )
"

# Dashboard version (from deployment image tag)
oc get deployment odh-dashboard -n redhat-ods-applications -o jsonpath='{.spec.template.spec.containers[0].image}' | sed 's/.*://'

# Supporting operators installed alongside RHOAI
oc get csv -n redhat-ods-operator -o custom-columns='NAME:.metadata.name,VERSION:.spec.version,PHASE:.status.phase' --no-headers
```

Record all outputs. The bug description MUST include ALL of the following:
- **OCP version** (OpenShift Container Platform)
- **RHOAI version** (Red Hat OpenShift AI operator version)
- **RHOAI build date** (from CSV `createdAt` annotation — useful for pre-release builds)
- **Dashboard version** (from the deployment image tag)
- **Affected component version** — from the DSC component list, include the specific upstream version of the component related to the bug (e.g., if the bug is in KServe, include `KServe v0.14.0`)
- **Supporting operator versions** — include only operators relevant to the bug area (e.g., Service Mesh version for serving bugs, Authorino for auth bugs)

---

## Phase 4: Gather Relevant Logs (Functional Bugs Only)

Skip this phase for documentation-only bugs.

Based on the affected component, gather logs:

| Bug area | Log command |
|----------|------------|
| Dashboard UI | `oc logs deployment/odh-dashboard -n redhat-ods-applications --tail=200` |
| Notebooks/workbenches | `oc logs <notebook-pod> -n <project-namespace> --tail=200` |
| Operator | `oc logs deployment/opendatahub-operator-controller-manager -n redhat-ods-operator --tail=200` |
| Model serving | `oc logs deployment/kserve-controller-manager -n redhat-ods-applications --tail=200` |

**CRITICAL SECRET SANITIZATION**: Before including ANY log content in the bug or attachments:
1. Remove all lines containing: `password`, `token`, `secret`, `key`, `bearer`, `credential`, `authorization`, `certificate`, `private`, `-----BEGIN`
2. Redact any values that look like tokens, API keys, or base64-encoded secrets
3. Redact any email addresses that are not Red Hat internal
4. If an entire log section appears to contain sensitive configuration, exclude it entirely
5. When in doubt, do NOT include the log content

---

## Phase 4.5: Impact Analysis

Assess the scope of the bug beyond the specific failure that was observed. This helps developers understand the blast radius and prioritize the fix.

1. **Identify the affected component/feature**: From the root cause identified in Phase 2, determine the specific UI component, API endpoint, operator controller, or configuration path that is broken.

2. **Trace impact**: Use the `Task` tool to launch an `explore` subagent with the following prompt:
   - Search the workflow-validation-director journeys (at `/home/dcohnlif/GIT/workflow-insights/data/journeys/`) for other workflows that interact with the same component/feature.
   - Search the RHOAI documentation (using `rhoai-docs_search_documentation`) for other documented procedures that reference the same feature.
   - Return: a list of other journeys/features that might be affected by the same bug, and why.

3. **Include in bug description**: Add the impact analysis results to the "Additional Information" section of the bug description (Phase 8). Format as:
   ```
   ## Impact Analysis
   The following areas may also be affected by this defect:
   - [Journey/feature name]: [why it's affected]
   - ...
   ```
   If no other areas are affected (the bug is isolated to a single workflow), note that explicitly: "Impact appears limited to the [specific feature] workflow."

---

## Phase 5: Search for Duplicate/Related Bugs

Search RHOAIENG using multiple JQL queries:

1. Search by key terms from the failure:
   ```
   project = RHOAIENG AND text ~ "<key term 1>" AND text ~ "<key term 2>" ORDER BY created DESC
   ```

2. Search by component and recent creation:
   ```
   project = RHOAIENG AND component = "<component>" AND created >= -180d ORDER BY created DESC
   ```

3. Read the summary and description of the top 5-10 matches.

**If an EXACT DUPLICATE is found** (same root cause, same behavior, same component, same version or later):
- Ask the user:
  > "Found exact duplicate: RHOAIENG-XXXXX — [summary] (Status: [status])
  > Options:
  > 1. Add new information as a comment to the existing bug
  > 2. Open a new bug anyway and link it as duplicate
  > 3. Leave it — do not file anything"
- Follow the user's choice.

**If SIMILAR or CLOSED bugs are found**: Note their keys for linking in Phase 11:
- CLOSED bugs with same symptoms → link as `Duplicate` (possible regression)
- OPEN bugs with related symptoms → link as `Relates to`

---

## Phase 6: Select the Best RHOAIENG Component

Fetch the component list using `atlassian_jira_get_project_components` for project `RHOAIENG`.

Map the failure area to the most relevant component:

| Failure area | Component | Source Repository |
|-------------|-----------|-------------------|
| Dashboard UI (Settings, Projects, Workbenches pages) | AI Core Dashboard | https://github.com/opendatahub-io/odh-dashboard |
| Platform operator, DSC, DSCI | AI Core Platform | https://github.com/opendatahub-io/opendatahub-operator |
| Platform security, RBAC, auth | AI Core Platform Security | https://github.com/opendatahub-io/opendatahub-operator |
| Notebooks, workbenches, JupyterLab | Notebooks Server | https://github.com/opendatahub-io/notebooks |
| Model serving (KServe, vLLM, runtime) | Model Serving | https://github.com/opendatahub-io/kserve |
| Pipelines (DSP, pipeline runs) | AI Pipelines | https://github.com/opendatahub-io/data-science-pipelines |
| Model registry, AI hub | AI Hub | https://github.com/opendatahub-io/model-registry |
| Documentation errors / UI-doc mismatch where docs are wrong | Documentation | https://github.com/opendatahub-io/opendatahub-documentation |
| Hardware profiles, accelerators | AI Core Dashboard | https://github.com/opendatahub-io/odh-dashboard |
| Distributed workloads, Ray, training | Distributed Workloads | https://github.com/opendatahub-io/distributed-workloads |

If uncertain which component is correct, ask the user.

**Record the source repository URL** from the table above -- it will be included in the bug description (Phase 8) to enable automated triage and autofix pipelines.

---

## Phase 7: Write the Summary

Write a clear, concise one-line summary (max ~100 chars):
- Format: `<Brief description of the defect>`
- Use present tense, describe what's broken
- Be specific -- include the UI page, feature, or API affected

Good examples:
- `PVC size setting on Cluster Settings page displays stale value after save and reload`
- `Workbench image dropdown shows pipe-separated names instead of documented display names`
- `Project permissions page shows "Manage permissions" button instead of documented "Add user"`

Bad examples:
- `Bug in dashboard` (too vague)
- `Settings page broken` (no specifics)

---

## Phase 8: Write the Description (MOST IMPORTANT)

Use this EXACT structure. Every section is mandatory:

```markdown
## Versions
- **OCP**: <OpenShift version from Phase 3>
- **RHOAI**: <version from Phase 3> (build: <build date if available>)
- **Dashboard**: <dashboard image tag version from Phase 3>
- **Affected component**: <upstream name and version from DSC status, e.g., "KServe v0.14.0" or "Kubeflow Pipelines 2.16.0">
- **Supporting operators**: <only those relevant to the bug, e.g., "Service Mesh 3.3.1, Authorino 1.3.0">
- **Dashboard URL**: <url>
- **Cluster**: <cluster identifier from dashboard URL>

## Setup / Scenario
<Describe the cluster configuration relevant to the bug.
What was the user trying to do? What journey/workflow was being executed?
What prerequisites were in place?>

## Steps to Reproduce
1. Log in to the OpenShift AI dashboard as an administrator
2. Navigate to Settings > Cluster settings
3. ...
<Exact steps. Number them. Be specific about navigation paths, button names, field values.>

## Expected Result
<What should have happened, citing the RHOAI documentation if applicable.
Example: "Per the RHOAI 3.4 documentation (Creating a workbench, step 9), the PVC size field should persist the saved value after page reload.">

## Actual Result
<What actually happened. Be specific.
Include error messages, unexpected values, UI behavior.
Example: "After saving PVC size to 5 GiB and receiving a 'Cluster settings changes saved' success notification, reloading the page shows the PVC size field reverted to 20 GiB.">

## Source Repository
<repository URL from Phase 6 table, e.g., https://github.com/opendatahub-io/odh-dashboard>

## Additional Information
<Any extra context: sanitized logs, workarounds, related observations.
Reference the workflow validation run that found this issue.>
```

---

## Phase 9: Write RCA and Fix Suggestion (If Possible)

If you can identify the root cause from logs, behavior, or code analysis, add:

```markdown
## Root Cause Analysis
<Your analysis. Example: "The PVC size input field appears to use a React controlled component where programmatic value changes via fill() do not trigger the onChange handler correctly. The 'Restore default' button uses a different code path (likely setState) that works correctly.">

## Suggested Fix
<Your suggestion. Example: "Ensure the PVC size input's onChange handler fires on all value change events, including programmatic updates. Consider using an onBlur handler as a fallback.">
```

If you cannot determine the root cause, omit this section entirely. Do NOT speculate.

---

## Phase 10: Human Approval Gate (MANDATORY)

Before creating the bug, present ALL gathered information to the user for review. Output the following:

```
## Bug Ready for Filing — Please Review

Summary:     <from Phase 7>
Type:        <Bug or Documentation Bug>
Component:   <from Phase 6>
Priority:    Medium
Project:     RHOAIENG

--- Description Preview ---
<full description from Phase 8, including Versions, Setup/Scenario, Steps to Reproduce, Expected Result, Actual Result>

<Phase 9 RCA if applicable>
--- End Preview ---

Reproduction:  <Reproduced via Playwright / Not reproduced / N/A (non-UI bug)>
Duplicates:    <None found / RHOAIENG-XXXXX (similar) / etc.>
Attachments:   <list of files to attach>
Linked Issues: <list of issues to link>
```

Then ask:
> "Do you want me to file this bug? (yes/no)"

- If the user says **yes**: proceed to Phase 11.
- If the user says **no** or asks for changes: apply the requested changes and re-present, or stop entirely.
- Do NOT create the Jira issue without explicit user confirmation.

---

## Phase 11: Create the Bug and Link Related Issues

Execute these steps in order:

1. **Create the issue**:
   Use `atlassian_jira_create_issue` with:
   - `project_key`: `RHOAIENG`
   - `issue_type`: `Bug`
   - `summary`: from Phase 7
   - `description`: from Phase 8 + Phase 9
   - `components`: from Phase 6
   - `additional_fields`: `{"priority": {"name": "Medium"}}`

2. **Set the reporter to Workflow Validation**:
   Use `atlassian_jira_update_issue` with:
   - `issue_key`: the key from step 1
   - `fields`: `{"reporter": "workflow-validation@redhat.com"}`

3. **Attach sanitized artifacts**:
   Before attaching each file, verify it contains NO secrets (passwords, tokens, keys, credentials, certificates, connection strings). Redact if needed.

   Use `atlassian_jira_update_issue` with `attachments` to attach:
   - `report.md` from the artifacts directory
   - `log.md` from the artifacts directory
   - `actions.md` from the artifacts directory
   - Any `.png` screenshot files from the artifacts directory
   - Any Playwright reproduction screenshots captured during Phase 2 verification
   - The DOM snapshot file (`.file-bug/dom_snapshot.html`) if captured during Phase 2 Playwright reproduction
   - Do NOT attach `.webm` screen recordings (too large)

4. **Link related issues** (from Phase 5):
   For each SIMILAR open bug:
   - `atlassian_jira_create_issue_link` with `link_type: "Relates to"`, `inward_issue_key: <new-bug>`, `outward_issue_key: <similar-bug>`

   For each EXACT DUPLICATE closed bug (possible regression):
   - `atlassian_jira_create_issue_link` with `link_type: "Duplicate"`, `inward_issue_key: <new-bug>`, `outward_issue_key: <closed-bug>`

---

## Phase 12: Report

Output a summary of what was done:

```
Bug Filed Successfully

Issue:     RHOAIENG-XXXXX
Summary:   <summary>
Component: <component>
Priority:  Medium
Reporter:  Workflow Validation
Link:      https://redhat.atlassian.net/browse/RHOAIENG-XXXXX

Attachments: report.md, log.md, actions.md, <screenshots>

Linked Issues:
  - RHOAIENG-YYYYY (Relates to) — <summary>
  - RHOAIENG-ZZZZZ (Duplicate) — <summary> [Resolved]
```

If no bug was filed (user chose to skip, or it wasn't a real bug), explain why.

### Record to Bug History

After filing (or commenting on an existing bug), update the history file at `.file-bug/history.json` in the workspace root (typically `/home/dcohnlif/GIT/workflow-validation-director/.file-bug/history.json`). Create the file and directory if they don't exist.

Append an entry with this structure:
```json
{
  "bug_key": "RHOAIENG-XXXXX",
  "summary": "<bug summary>",
  "journey": "<journey/workflow name>",
  "failed_tasks": ["<task1>", "<task2>"],
  "error_signature": "<first 200 chars of the key error message>",
  "component": "<RHOAIENG component>",
  "filed_date": "<ISO 8601 date>",
  "artifacts_path": "<path to the artifacts directory>",
  "reproduction": "<reproduced_playwright | not_reproduced | not_applicable>",
  "impact": ["<other affected journey/feature 1>", "..."]
}
```

This history enables Phase 1.5 to catch recurring failures and prevent duplicate bug filings.
