---
applyTo: '**'
---
# Personal Coding Style Preferences

## Core Principles
- When asked to solve a problem
    - For most tasks, always prefer sharing a plan first and ask for confirmation before making any code changes
    - If it's an extremely straightforward and clear ask, directly implement the solution (e.g., "fix this bug", "add this argument", "change this function name")
- Keep code minimal and compact - avoid bloated solutions
- When asked for implementation, just create a very minimal script/do minimal changes, nothing else, no bloat
- Focus only on the task at hand, no unnecessary features and changes
- Do optimal changes to existing code. When implementing new features, new experiments:
    - First think about how to best bring about the change given the existing code
    - If the feature / experiments can be implemented in a backwards-compatible way, do so
    - If major significant changes are needed, do that in a compact manner first in a similar style as the rest of the code
- When implementing new features, think about possible design patterns that would make obvious future extensions easier
- Use clear, concise variable and function names
- Don't over-document - only document absolute necessary bits using very few words. I can understand obvious things myself, skip explaining the basics.
- Complete tasks in phases to help with debugging

## Code Structure
- Automate everything end-to-end with minimal user prompts
- Use clear, descriptive function names
- Group related functionality together
- Don't change existing functionality much when adding features
- Make code modular with functions for repetitive tasks
- Refactor common bits and pieces into reusable functions

## Documentation Style
- Very brief comments only for non-obvious parts
- No verbose explanations of standard operations
- Use concise variable/function names that are self-explanatory

## Communication Style
- Direct and to-the-point
- Mention testing approach when relevant
- Iterative development - build and refine as we go
- Focus on practical implementation over theory