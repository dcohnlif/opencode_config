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
   e. If the bug reproduces: this is strong evidence. Save the screenshot for attachment in Phase 10.
   f. If the bug does NOT reproduce: note this -- it may have been a transient issue or already fixed. Inform the user and ask whether to proceed.

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

# RHOAI version
oc get csv -n redhat-ods-operator -o jsonpath='{.items[0].spec.version}'

# RHOAI operator status
oc get dsci -A -o jsonpath='{.items[0].status.phase}'

# Dashboard route
oc get route -n redhat-ods-applications -l app=odh-dashboard -o jsonpath='{.items[0].spec.host}'
```

Record: OCP version, RHOAI version, DSCI status, Dashboard URL.

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

**If SIMILAR or CLOSED bugs are found**: Note their keys for linking in Phase 10:
- CLOSED bugs with same symptoms → link as `Duplicate` (possible regression)
- OPEN bugs with related symptoms → link as `Relates to`

---

## Phase 6: Select the Best RHOAIENG Component

Fetch the component list using `atlassian_jira_get_project_components` for project `RHOAIENG`.

Map the failure area to the most relevant component:

| Failure area | Component |
|-------------|-----------|
| Dashboard UI (Settings, Projects, Workbenches pages) | AI Core Dashboard |
| Platform operator, DSC, DSCI | AI Core Platform |
| Platform security, RBAC, auth | AI Core Platform Security |
| Notebooks, workbenches, JupyterLab | Notebooks Server |
| Model serving (KServe, vLLM, runtime) | Model Serving |
| Pipelines (DSP, pipeline runs) | AI Pipelines |
| Model registry, AI hub | AI Hub |
| Documentation errors / UI-doc mismatch where docs are wrong | Documentation |
| Hardware profiles, accelerators | AI Core Dashboard |
| Distributed workloads, Ray, training | Distributed Workloads |

If uncertain which component is correct, ask the user.

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
- **RHOAI**: <version from Phase 3>
- **OCP**: <version from Phase 3>
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

## Phase 10: Create the Bug and Link Related Issues

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
   - Do NOT attach `.webm` screen recordings (too large)

4. **Link related issues** (from Phase 5):
   For each SIMILAR open bug:
   - `atlassian_jira_create_issue_link` with `link_type: "Relates to"`, `inward_issue_key: <new-bug>`, `outward_issue_key: <similar-bug>`

   For each EXACT DUPLICATE closed bug (possible regression):
   - `atlassian_jira_create_issue_link` with `link_type: "Duplicate"`, `inward_issue_key: <new-bug>`, `outward_issue_key: <closed-bug>`

---

## Phase 11: Report

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
