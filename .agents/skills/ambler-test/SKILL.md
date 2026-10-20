---
name: ambler-test
description: Adds or updates tests for an existing Ambler (Mojo) node that already has an implementation. Use this when a node exists in nodes/<name>.mojo but has no test file, when tests need extending after new branches were added, or when retrofitting TDD onto existing code. For creating a brand-new node with tests, use `/ambler-node` instead.
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Test (Mojo)

Follow these steps to add or update tests for an existing node in `nodes/`.

> For brand-new nodes, use `/ambler-node` — it creates both the implementation and tests via a TDD cycle. Write all Mojo with the `mojo-syntax` skill loaded.

---

## 1. Read the existing node

Read `nodes/<name>.mojo` in full. Identify:

- The **`State`** trait (accessors the test state must implement), **`Edges`** fields, and **`Utils`** trait methods (each needs a fake).
- **All branches**: every `return Next(self.edges.on_<edge>, state^)` is one branch. List them all — each becomes a test.

---

## 2. Check for existing tests

Check whether `nodes/tests/test_<name>.mojo` exists.

- **Does not exist**: write a complete test file covering every branch.
- **Exists**: read it, list uncovered branches, and add only those. Don't rewrite passing tests unless the node's interface changed.

---

## 3. Write or update `nodes/tests/test_<name>.mojo`

```mojo
from std.testing import TestSuite, assert_equal, assert_false

from nodes import <name>


@fieldwise_init
struct State(<name>.State):
    var _host: String

    def host(self) -> String:
        return self._host

    def set_host(mut self, value: String):
        self._host = value


@fieldwise_init
struct FakeUtils(<name>.Utils):
    var answer: Optional[String]   # canned input
    var printed: List[String]      # recorded output

    def get_prompt(mut self, msg: String) -> Optional[String]:
        return self.answer

    def print_line(mut self, msg: String):
        self.printed.append(msg)


def test_<behavior>_when_<condition>() raises:
    var node = <name>.Node(
        <name>.Edges(on_success=String("next"), on_error=String("retry")),
        FakeUtils(String("http://right:11434"), []),
    )
    var result = node.run(State("http://wrong:11434"))
    assert_equal(result.node.value(), "retry")
    assert_equal(result.state.host(), "http://right:11434")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
```

### Test rules

- **One test per branch** — cover every `Next(self.edges.on_<edge>, ...)` return.
- **Fake all `Utils`** — no real I/O, network, or timing. A util that `raises` in the trait may raise in the fake to test error paths.
- **Assert `result.node`** (`.value()` for an edge, `assert_false(result.node)` for terminal `None`) and **`result.state`**.
- **Test names**: `test_<expected_behavior>_when_<condition>`.
- A shared `make_node(...)` helper keeps per-test setup to the parts that differ.

---

## 4. Run tests — must pass

```bash
pixi run mojo run -I . nodes/tests/test_<name>.mojo
pixi run test   # whole suite
```

If any fail, fix the implementation (not the tests). (`mojo test` was removed — test files are run with `mojo run` and `TestSuite`.)

---

## 5. Checklist before finishing

- [ ] `nodes/tests/test_<name>.mojo` has one test per branch.
- [ ] All `Utils` are faked — no real I/O, network, or timing.
- [ ] Test names follow `test_<behavior>_when_<condition>`.
- [ ] `pixi run test` passes.
