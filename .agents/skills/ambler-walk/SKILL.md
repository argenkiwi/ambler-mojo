---
name: ambler-walk
description: Creates a complete Ambler (Mojo) walk — the Mojo wiring file (walks/<name>.mojo) and the Markdown spec (specs/<name>.md) — and ensures all required nodes exist. Use this whenever a user wants to add a new program or flow to an Ambler Mojo project, even if they say "new walk", "add a program", "wire up these nodes", or just describe what they want the app to do.
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Walk (Mojo)

A walk is a state-machine program consisting of two files:

1. `walks/<name>.mojo` — the shared `State` struct, the node IDs, and a `Walk` struct that wires nodes together.
2. `specs/<name>.md` — Markdown specification of the shared state and each node's logic/transitions.

Write all Mojo with the `mojo-syntax` skill loaded.

---

## Step 1 — Identify the Walk

- Walk name: snake_case (e.g. `my_walk`); the file is `walks/<name>.mojo`.
- Its purpose, the nodes it needs and their transitions.

## Step 2 — Research and Reuse

- **Review Existing Specs:** browse `specs/*.md` for nodes that already implement the required logic.
- **Check Node Implementation:** confirm each exists as `nodes/<name>.mojo`.

## Step 3 — Create the Specification (`specs/<name>.md`)

Use the `/ambler-spec` skill. It is the blueprint for the walk.

## Step 4 — Ensure Nodes Exist

- Missing node → `/ambler-node` (full TDD pass).
- Node exists without tests → `/ambler-test`.

---

## Step 5 — Create the Wiring File (`walks/<name>.mojo`)

```mojo
from ambler import Next, Walk, amble, node_not_found
from nodes import count, start, stop


# Implements every node's State trait; field names are free to differ.
@fieldwise_init
struct State(count.State, start.State, stop.State):
    var value: Int

    def count(self) -> Int:
        return self.value

    def set_count(mut self, value: Int):
        self.value = value


comptime START = "START"
comptime COUNT = "COUNT"
comptime STOP = "STOP"


struct Counter(Walk):
    comptime State = State

    var start: start.Node[]
    var count: count.Node[]
    var stop: stop.Node[]

    def __init__(out self):
        self.start = start.Node(
            start.Edges(on_success=String(COUNT), on_error=String(START)),
            start.DefaultUtils(),
        )
        self.count = count.Node(
            count.Edges(on_count=String(COUNT), on_stop=String(STOP)),
            count.DefaultUtils(),
        )
        self.stop = stop.Node(stop.Edges(on_done=None), stop.DefaultUtils())

    def step(
        mut self, node_id: String, var state: Self.State
    ) raises -> Next[Self.State]:
        if node_id == START:
            return self.start.run(state^)
        if node_id == COUNT:
            return self.count.run(state^)
        if node_id == STOP:
            return self.stop.run(state^)
        raise node_not_found(node_id)


def main() raises:
    var walk = Counter()
    _ = amble(walk, START, State(0))
```

**Key rules:**
- Import `Next, Walk, amble, node_not_found` from `ambler`; import node modules with `from nodes import ...`.
- Define node IDs as `comptime` string constants (ALL_CAPS, matching the spec).
- The walk's `State` struct conforms to every wired node's `State` trait.
- The `Walk` struct sets `comptime State = State`, holds one field per node (`<module>.Node[]` uses the default `DefaultUtils`), wires edges in `__init__`, and dispatches in `step` with one `if node_id == X:` per node, ending in `raise node_not_found(node_id)`.
- Terminal edges are `None`.
- Nodes are built eagerly — unlike ambler-ts there is no lazy loading; compiled Mojo has no module-load cost to defer.
- Stable Mojo 1.1 has no `match` on strings yet; use the `if` chain.

---

## Step 6 — Add a pixi task

```bash
pixi task add <name> "mojo run -I . walks/<name>.mojo"
```

If the walk's utils use Python interop, make sure the project has a Python with a shared `libpython` (`pixi add "python>=3.13,<3.14"` — conda-forge's 3.15 build has none, and Mojo aborts with "Failed to load libpython").

## Step 7 — Verify

```bash
pixi run test        # if the walk added nodes
pixi run <name>      # run it; pipe input to script it: printf '3\n' | pixi run <name>
```

---

## Checklist

- [ ] `specs/<name>.md` exists and its node names match the walk's IDs.
- [ ] `walks/<name>.mojo` has the `State` struct, node ID constants, `Walk` struct and `main`.
- [ ] Every node used has `nodes/<name>.mojo` with passing tests.
- [ ] `pixi run test` passes.
- [ ] `pixi.toml` has a task for the walk.
- [ ] The walk runs end-to-end.
