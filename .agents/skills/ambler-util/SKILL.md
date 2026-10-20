---
name: ambler-util
description: Creates or extracts utility modules into the utils/ directory of an Ambler (Mojo) project. Use this whenever a node's DefaultUtils needs Python interop, an external dependency, logic reusable across multiple nodes, or an implementation too complex to inline — even if the user just says "add a util", "extract this helper", "share this function", "create a utility", or "this code is getting too long for the node". When a user creates a node that needs HTTP, files, or a Python library, proactively suggest using this skill.
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Util (Mojo)

Follow these steps to create or extract a utility module in `utils/`. Write all Mojo with the `mojo-syntax` skill loaded, plus `mojo-python-interop` when the util calls Python.

## When to create a utility

Create `utils/<name>.mojo` when a node's `DefaultUtils` contains:

1. **Python interop** — Mojo's stdlib has no HTTP client, JSON parser, etc.; reaching for `std.python` belongs in a util.
2. **Reusable logic** — used, or likely to be used, by more than one node (e.g. `utils/prompt.mojo get_prompt`).
3. **Complex implementations** — error handling, retries, multi-step operations that clutter the node.

One-liners like `print(msg)` or `random_float64()` stay in `DefaultUtils` directly.

---

## 1. Gather requirements

- **Utility name**: snake_case capability (`llm_chat`, `file_writer`). File: `utils/<name>.mojo`.
- **Functions to export**: signatures, argument and return types, and whether they `raise`.
- **Dependencies**: Python packages (added with `pixi add <pkg>` from conda-forge, or `pixi add --pypi <pkg>`).
- **Nodes that will use it.**

If unclear, ask the user before writing code.

---

## 2. Create `utils/<name>.mojo`

```mojo
"""Client for OpenAI-compatible chat APIs.

Mojo's stdlib has no HTTP client, so requests go through Python's
`urllib.request` via Python interop.
"""

from std.python import Python, PythonObject

comptime DEFAULT_TIMEOUT = 5


def list_models(host: String) raises -> List[String]:
    """Lists available models from the LLM host.

    Args:
        host: The API host URL (e.g. http://localhost:11434/v1).

    Returns:
        The model IDs.

    Raises:
        If the request fails or the response is malformed.
    """
    var request = Python.import_module("urllib.request")
    var json = Python.import_module("json")
    var data = json.loads(request.urlopen(host + "/models").read())
    var models = List[String]()
    for model in data["data"]:
        models.append(String(py=model["id"]))
    return models^
```

### Rules

- **Export functions (and plain data structs)** — e.g. `Message` in `utils/llm_chat.mojo`. Never export module-level mutable state.
- **Mojo types at the boundary** — convert `PythonObject` to `String`/`Int`/`List` inside the util (`String(py=obj)`, `Int(py=obj)`), so nodes and their fakes never see Python.
- **Match the node's `Utils` trait** — the util's signature should be what `DefaultUtils` delegates to with no glue.
- **`raises` honestly** — anything calling Python raises; either mark the function `raises` or catch and return a fallback (`check_host` returns `False`).
- **No Ambler imports** — utils must not import from `ambler`.
- **Extract constants** — URLs, timeouts, defaults as `comptime` declarations at the top.
- **Docstrings** — every exported function gets a Mojo docstring with `Args:`, `Returns:` and (if it raises) `Raises:` sections.

### Python environment gotcha

Python interop needs a Python with a shared `libpython`. conda-forge's Python 3.15 ships none, so Mojo aborts at runtime with "Failed to load libpython". Pin one that does:

```bash
pixi add "python>=3.13,<3.14"
```

---

## 3. Connect to the node

Delegate from the node's `DefaultUtils`; the `Utils` trait stays unchanged.

```mojo
from utils.llm_chat import list_models


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def list_models(mut self, host: String) raises -> List[String]:
        return list_models(host)
```

Tests keep using fakes and never touch the util — that's the point of the `Utils` trait. Exercise the util itself with a quick scratch program (or a local stub server for network utils) rather than in node tests.

---

## 4. Checklist before finishing

- [ ] `utils/<name>.mojo` exists and exports the required functions.
- [ ] Python packages are in `pixi.toml`; Python has a shared `libpython` if interop is used.
- [ ] Exported signatures match the node's `Utils` trait; no `PythonObject` leaks out.
- [ ] Constants are `comptime` declarations.
- [ ] Every exported function has a docstring.
- [ ] The node's `DefaultUtils` delegates to the util.
- [ ] No `ambler` imports in the util.
- [ ] `pixi run test` still passes (node tests use fakes, so they need no changes).
