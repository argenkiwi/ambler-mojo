# Ambler (Mojo)

[![Mojo](https://img.shields.io/badge/mojo-^1.1-orange.svg)](https://mojolang.org/)
[![pixi](https://img.shields.io/badge/pixi-managed-yellow.svg)](https://pixi.sh/)

Ambler is a lightweight state-machine framework for building programs as executable graphs. This is the Mojo port of [ambler-ts](https://github.com/argenkiwi/ambler-ts). It is the architectural foundation that lets coding agents construct, test and wire complex workflows, known as **walks**.

## 🚀 Key Features

- **Tiny engine**: `ambler.mojo` is a `Next` result type, a `Walk` trait and an `amble` driver loop.
- **Trait-based nodes**: each node sees only the state it needs, through a `State` trait. Side effects go through a `Utils` trait, so nodes are reusable across walks and testable with fakes.
- **Spec-first workflow**: Markdown specifications bridge the gap between design and implementation.
- **Agent-optimised**: a suite of agent skills for scaffolding and testing, plus Modular's Mojo skills to keep generated code on current syntax.

---

## 🏁 Quick Start

```bash
# Install pixi if needed: https://pixi.sh
pixi install          # Mojo (stable) + Python 3.13
pixi run test         # run every node test
pixi run counter      # the counter example
pixi run chat         # chat with a local OpenAI-compatible LLM (Ollama, LM Studio)
```

### For agentic development (recommended)

Install the Ambler skills, plus Modular's Mojo skills so agents write current Mojo syntax, using [`skills`](https://github.com/argenkiwi/skills):

```bash
npx skills add argenkiwi/ambler-mojo
npx skills add modular/skills --skill mojo-syntax --skill new-modular-project --skill mojo-python-interop
```

In a clone of this repo, the `ambler-*` skills are already in `.agents/skills/`. Run the second command to link every skill into `.claude/skills/` for Claude Code.

To bootstrap a new project from your agent session:

```bash
/ambler-init <target-dir>
```

---

## 🏗️ Architecture

### 1. Engine (`ambler.mojo`)

| Piece | Role |
|---|---|
| `Next[S]` | A node's result: `node: Optional[String]` (the next node ID, `None` stops the walk) and the updated `state`. |
| `Walk` trait | `comptime State` plus `step(node_id, state) -> Next[State]`, which dispatches to the matching node. Unknown IDs raise `node_not_found`. |
| `amble(walk, start, state)` | Runs the walk until a node returns `None`, then returns the final state. |

### 2. Nodes (`nodes/`)

Every node module exports the same five names:

- `State` (trait): the accessors the node needs, e.g. `count()` / `set_count()`.
- `Edges` (struct): one `Optional[String]` per logical exit, e.g. `on_success`, `on_error`.
- `Utils` (trait): injected side effects, e.g. `print_line`, `read_line`.
- `DefaultUtils`: the production `Utils`.
- `Node[U: Utils = DefaultUtils]`: holds edges and utils. `run[S: State](state) -> Next[S]` holds the logic.

### 3. Walks (`walks/`)

A walk defines a `State` struct that implements every wired node's `State` trait, `comptime` node IDs, and a `Walk` struct that builds the nodes and dispatches in `step`. `main()` calls `amble`.

### 4. Utils (`utils/`)

Shared or heavyweight helpers. Mojo's stdlib has no HTTP client, so `utils/llm_chat.mojo` calls Python's `urllib` through Python interop. `utils/prompt.mojo` reads stdin line by line.

### 5. Specs (`specs/`)

Markdown blueprints that describe the intended behaviour and state transitions before any code is written. They are language-agnostic and shared in spirit with ambler-ts.

### 6. Zettelkasten-RAG (`notes/` + `.azk/`)

Design decisions and gotchas live as atomic notes in `notes/`, indexed by the global `azk` CLI. See `AGENTS.md` for the protocol.

---

## 🔁 Differences from ambler-ts

| ambler-ts | ambler-mojo | Why |
|---|---|---|
| Map of lazily-loaded node factories | `Walk.step` if-chain, nodes built eagerly | Mojo has no trait objects, and compiled code has no module-load cost to defer. |
| Structural `S extends NS` state | `State` traits with accessors | Mojo has no structural typing. Traits keep nodes reusable, and adapter nodes become unnecessary. |
| `async` nodes | Synchronous nodes | Mojo async is still unstable. |
| `fetch` | Python `urllib` via interop | There is no HTTP client in Mojo's stdlib. |
| `prompt()` | Byte-wise stdin reader | Mojo 1.1's `input()` drops lines from piped stdin. |
| `parseInt` | `Int(String)` | Stricter: `"12abc"` is rejected rather than read as 12. |
| init / clone walks | Not ported yet | They are Deno-specific scaffolding. The `ambler-init` skill covers project creation. |

---

## 🛠️ Developer Workflow

1. **Specify**: define the graph in `specs/` (`/ambler-spec`).
2. **Implement**: build nodes in `nodes/` (`/ambler-node`).
3. **Test**: verify node logic in `nodes/tests/` (`/ambler-test`).
4. **Compose**: wire nodes together in `walks/` (`/ambler-walk`).
5. **Execute**: `pixi run <walk>`.

```bash
pixi run test                                        # all node tests
pixi run mojo run -I . nodes/tests/test_count.mojo   # one node's tests
printf '3\n' | pixi run counter                      # scripted run
```

---

Built with ❤️ by [argenkiwi](https://github.com/argenkiwi)
