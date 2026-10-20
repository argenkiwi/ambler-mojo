---
name: ambler-spec
description: Creates or updates a Markdown specification file for an Ambler (Mojo) walk in the specs/ directory. Use this whenever a user wants to document, plan, or describe a walk — including "write a spec", "document this walk", or "plan out the nodes" — even before any code exists.
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Specification

This skill creates a Markdown specification (`specs/<walk-name>.md`) for an Ambler walk: the program's flow (nodes and edges) and the shared state. Specs are language-agnostic — they describe *what* the program does, so the same spec could drive the TypeScript or the Mojo implementation.

## Instructions

### 1. Identify the Walk's Name and Purpose

- If not provided, ask the user for the name and a brief description.
- The file is `specs/<name>.md` (same snake_case name as `walks/<name>.mojo`).

### 2. Map the Nodes and Edges

- Identify every **Node** (discrete step) and its **Edges** (possible transitions).
- One `### <Node Name>` subsection per node under `## Nodes`, describing its role, logic, and edges.

### 3. Determine the Shared State

- Look at what each node needs to read or change, then derive the state from that — don't guess it first.
- Describe it under `## Shared State`. In the Mojo implementation each node turns its slice of this into a `State` trait, and the walk's `State` struct implements them all.

### 4. Format the Markdown

```markdown
# Program Specifications

<Brief description of the program and its purpose.>

## Nodes

### <Node Name 1>
- <Role — e.g., "Initial node.">
- <Logic — e.g., "Prompts the user to enter X.">
- <Edges — e.g., "If valid, transitions to `NEXT`. If invalid, transitions to `START`.">

### <Node Name N>
- <Role — e.g., termination node.>
- <Logic.>
- <Termination — e.g., "Displays result and terminates.">

## Shared State

<Description of the state, derived from the collective needs of the nodes.>
```

### 5. Write the File

Use the Write tool to create `specs/<name>.md`.

## Guidelines

- **Consistency**: browse `specs/*.md` first to find reusable nodes and match the house style.
- **Node name casing**: Title Case headings (`### Count`); backtick-quoted ALL_CAPS in edge descriptions (`` `COUNT` ``) — these become the walk's `comptime` node IDs.
- **Clarity**: describe behavior, not implementation.
- **Implementation alignment**: if `walks/<name>.mojo` exists, the spec must reflect it; otherwise the spec is the blueprint.
- **No extra sections**: stick to `# Program Specifications`, `## Nodes`, `## Shared State`.

## Example

See `specs/counter.md`.
