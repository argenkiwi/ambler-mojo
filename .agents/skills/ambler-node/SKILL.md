---
name: ambler-node
description: Creates a new Ambler (Mojo) node — with tests, using test-driven development. Use this whenever the user wants to add a node, step, or state to an Ambler Mojo project — even if they phrase it as "add a step", "create a handler", or describe the behavior without using the word "node". Also use when creating a node WITH tests or following TDD for a new node. For adding tests to an existing node that already has an implementation, use `/ambler-test` instead.
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Node (Mojo)

Follow these steps to create a new node using test-driven development. Tests are written before the implementation.

> **Write all Mojo with the `mojo-syntax` skill loaded** (`npx skills add modular/skills --skill mojo-syntax`). It overrides pretrained Mojo knowledge — `def` not `fn`, `std.` imports, `var`/`mut`/`out`, explicit `raises`.

## 1. Gather requirements

Before writing any code, determine:

- **Research Existing Nodes:** Check `specs/*.md` and `nodes/` for a node with similar behavior. Reuse beats duplication — and because nodes only see their state through a trait, an existing node can usually be reused as-is by implementing its `State` trait on the walk's state.
- **Node name**: snake_case (Mojo module names can't contain `-`), e.g. `retry`, `llm_check`. The file is `nodes/<name>.mojo`.
- **State accessors**: What does the node read or change? Each becomes a method on the node's `State` trait (`def count(self) -> Int`, `def set_count(mut self, value: Int)`). Keep it minimal.
- **Edges**: What named transitions can the node take? Each becomes an `Optional[String]` field on `Edges` (`on_success`, `on_error`, …).
- **Utils**: What side effects does it perform (printing, reading input, network, time, randomness)? Each becomes a method on the `Utils` trait, with a production implementation in `DefaultUtils`. Use `print_line`, not `print` — don't shadow the builtin.
- **Behavior**: What does the node do, and how does it choose an edge?
- **Branches**: Every edge the node can return is one test case. The traits and branches decided here are the contract — if they need to change during implementation, restart from this step.

There is no async: Mojo async is unstable, so nodes are synchronous (`std.time.sleep`, blocking I/O).

---

## 2. Create a skeleton `nodes/<name>.mojo`

Write the traits, `Edges`, `DefaultUtils` and a `Node` whose `run` raises, so tests fail in step 4.

```mojo
from ambler import Next


trait State(Deinitable, Movable):
    def count(self) -> Int:
        ...

    def set_count(mut self, value: Int):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_success: Optional[String]
    var on_error: Optional[String]


trait Utils(Deinitable, Movable):
    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def print_line(mut self, msg: String):
        print(msg)


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        raise Error("not implemented")
```

Every node module exports the same five names — `State`, `Edges`, `Utils`, `DefaultUtils`, `Node` — so walks and tests address them as `<name>.Node`, `<name>.Edges`, etc. A node that needs no state accessors takes `run[S: Deinitable & Movable]` and omits the `State` trait (see `nodes/chat_bye.mojo`).

Verify the skeleton compiles before writing tests:

```bash
pixi run mojo build -I . nodes/<name>.mojo -o /dev/null 2>&1 | grep -v "does not contain a 'main' function"
```

No output means it compiles (the only message filtered out is the expected absence of `main`).

---

## 3. Write `nodes/tests/test_<name>.mojo`

One `test_*` function per branch from step 1. Fakes replace every util — no real I/O, network or timing. Fakes may record calls in fields because `Utils` methods take `mut self`.

```mojo
from std.testing import TestSuite, assert_equal, assert_false

from nodes import <name>


@fieldwise_init
struct State(<name>.State):
    var value: Int

    def count(self) -> Int:
        return self.value

    def set_count(mut self, value: Int):
        self.value = value


@fieldwise_init
struct FakeUtils(<name>.Utils):
    var printed: List[String]

    def print_line(mut self, msg: String):
        self.printed.append(msg)


def make_node() -> <name>.Node[FakeUtils]:
    return <name>.Node(
        <name>.Edges(on_success=String("next"), on_error=String("error")),
        FakeUtils([]),
    )


def test_<behavior>_when_<condition>() raises:
    var node = make_node()
    var result = node.run(State(5))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state.count(), 6)
    assert_equal(node.utils.printed, ["..."])


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
```

### Test rules

- **One test per branch** — one for each edge the node can return.
- **Fake all `Utils`** — deterministic, side-effect-free structs.
- **Assert `result.node`** for the next node ID (`assert_false(result.node)` for a terminal `None`) and **`result.state`** for the updated state.
- **Test names**: `test_<expected_behavior>_when_<condition>`.
- Annotate collection literals of structs (`var xs: List[Message] = [...]`) — unannotated they infer to `Array`.

---

## 4. Run tests — expect failure

```bash
pixi run mojo run -I . nodes/tests/test_<name>.mojo
```

Tests must fail with `not implemented` (or assertion errors).

- Fail with `not implemented` → correct, proceed to step 5.
- Fail with a **compile error** → the skeleton's traits don't match the test — fix the skeleton, not the tests.
- **Pass** → the skeleton was too complete; make `run` raise.

---

## 5. Implement `run`

Replace the stub body. The traits, `Edges` and `DefaultUtils` stay exactly as written in step 2.

```mojo
    def run[S: State](mut self, var state: S) raises -> Next[S]:
        self.utils.print_line(String(t"Current count: {state.count()}"))
        state.set_count(state.count() + 1)
        return Next(self.edges.on_success, state^)
```

### Key rules

- **Ownership, not spreading**: the node owns `state` (`var state: S`), updates it through the trait's setters, and transfers it out with `state^`. Never keep a reference to it after returning.
- **Utils**: all side effects go through `self.utils.*`. Complex or reusable logic (HTTP, file I/O, Python interop) belongs in `utils/` via `/ambler-util`.
- **Termination**: terminal nodes are wired with `None` in the walk (`stop.Edges(on_done=None)`).
- **t-strings**: wrap in `String(t"...")` when passing to a `String` parameter.
- **Do not modify the tests** between steps 4 and 6.

### Adapters are rarely needed

In ambler-ts an adapter node renamed state properties. In Mojo the walk's `State` struct implements each node's `State` trait itself, so it can map `count()` onto whatever field it likes. Write an adapter node only when the *behavior* must change.

---

## 6. Run tests — must pass

```bash
pixi run mojo run -I . nodes/tests/test_<name>.mojo
```

Fix the implementation (never the tests) until green. Then run the full suite: `pixi run test`.

---

## 7. Checklist before finishing

- [ ] `nodes/<name>.mojo` exports `State`, `Edges`, `Utils`, `DefaultUtils`, `Node`.
- [ ] Edge fields use the `on_<event>` naming convention and are `Optional[String]`.
- [ ] `State` trait is minimal (only the accessors the node uses).
- [ ] `DefaultUtils` provides real implementations.
- [ ] Shared/complex logic is in `utils/`.
- [ ] `nodes/tests/test_<name>.mojo` has one test per branch, all utils faked.
- [ ] Tests were written (step 3) before the implementation (step 5), failed in step 4 and pass in step 6.
- [ ] `pixi run test` is green.
