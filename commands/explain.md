---
description: Explain a file, function, or module with a dependency map and Mermaid diagram. Great for onboarding and code understanding.
---

# Code Explainer

This command takes a file path, function name, or module and produces a clear explanation with a visual dependency diagram. Useful for onboarding new team members or understanding unfamiliar code.

## Input

```text
$ARGUMENTS
```

## Instructions

1. **Identify the target**: Parse the user's input to determine what to explain. It could be:
   - A file path (e.g., `src/auth/login.py`)
   - A function or class name (e.g., `authenticate_user`)
   - A module or directory (e.g., `src/services/`)
   - A concept described in words (e.g., "the authentication flow")

2. **Read the code**: Read the target file(s). If a function/class name was given without a path, search the codebase to locate it.

3. **Map dependencies**: Use the `Task` tool to launch an `explore` subagent that:
   - Traces all imports and dependencies of the target
   - Identifies what calls the target (callers) and what the target calls (callees)
   - Finds related test files
   - Maps the data flow (what goes in, what comes out)
   - Returns a structured dependency map

4. **Generate the explanation**: Produce a structured explanation with these sections:

   ```
   ## Overview
   One paragraph: what this code does, why it exists, and where it fits
   in the larger system.

   ## Key Components
   - List of functions/classes with one-line descriptions
   - Entry points and exit points

   ## How It Works
   Step-by-step walkthrough of the logic flow. Use numbered steps.
   Reference specific line numbers (file_path:line_number).

   ## Dependencies
   - **Imports**: what this code depends on
   - **Callers**: what calls this code
   - **Called by**: what this code calls

   ## Dependency Diagram
   ```mermaid
   graph TD
       A[caller_1] --> B[target_function]
       A2[caller_2] --> B
       B --> C[dependency_1]
       B --> D[dependency_2]
       D --> E[sub_dependency]
   ```

   ## Testing
   - Related test files and what they cover
   - How to run the tests

   ## Gotchas
   - Non-obvious behavior, edge cases, or common mistakes
   - Any technical debt or known issues
   ```

5. **Adapt depth to scope**:
   - For a single function: focus on the function logic, parameters, return values, and immediate callers/callees
   - For a file: cover all public functions/classes and their relationships
   - For a module/directory: provide a high-level architecture overview with a component-level Mermaid diagram
   - For a concept: trace the flow across multiple files and show the end-to-end path

6. **Store in memory**: If the Memory MCP is available, store the key relationships discovered during this explanation for future reference.
