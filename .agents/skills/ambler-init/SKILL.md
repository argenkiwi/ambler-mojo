---
name: ambler-init
description: Initializes a new Ambler (Mojo) state-machine project. Use this whenever a user wants to start a new Ambler Mojo project, bootstrap a state-machine app in Mojo, or set up the Ambler folder structure — even if they just say "new project" or "set up ambler" or "create ambler folder".
metadata:
  author: leandro
  version: "1.0"
---

# Ambler Init (Mojo)

This skill initializes a new Ambler project in Mojo, managed with pixi.

## Template Files

| Source (skill `assets/`) | Writes to |
|--------|-----------|
| `ambler.mojo` | `<target>/ambler.mojo` |

---

## Steps

### 1. Determine the target directory

- If the user provided a directory path, use it; otherwise use `.`.

### 2. Make sure pixi is installed

```bash
pixi --version || curl -fsSL https://pixi.sh/install.sh | sh
```

(After installing, `~/.pixi/bin` may need to be added to `PATH` for the current shell.) Mojo also needs a C linker — on macOS, `xcode-select --install`.

### 3. Initialise the pixi project with Mojo (stable channel)

Follow the `new-modular-project` skill if it is installed; the commands are:

```bash
pixi init "<target>" -c https://conda.modular.com/max/ -c conda-forge
cd "<target>" && pixi add mojo
```

Don't pin a Mojo version — the channel resolves it. If `pixi.toml` already exists, skip `pixi init` and just `pixi add mojo`.

### 4. Create the directory structure

```bash
mkdir -p "<target>/nodes/tests" "<target>/walks" "<target>/specs" "<target>/utils"
touch "<target>/nodes/__init__.mojo" "<target>/utils/__init__.mojo"
```

The empty `__init__.mojo` files make `nodes` and `utils` importable packages.

### 5. Write the engine

Read `assets/ambler.mojo` and write it to `<target>/ambler.mojo`. Do not modify it.

### 6. Add the test task

```bash
cd "<target>" && pixi task add test "sh -c 'for f in nodes/tests/test_*.mojo; do mojo run -I . \"\$f\" || exit 1; done'"
```

### 7. Install the Mojo agent skills

So future agents write current Mojo syntax:

```bash
cd "<target>" && npx skills add modular/skills --skill mojo-syntax --skill new-modular-project --skill mojo-python-interop
```

### 8. Verify

```bash
cd "<target>" && pixi run mojo build -I . ambler.mojo -o /dev/null 2>&1 | grep -v "does not contain a 'main' function"
```

No output means the engine compiles (the only message filtered out is the expected absence of `main`).

### 9. Report success

```
Initialized Ambler (Mojo) project in "<target>":
  ambler.mojo
  pixi.toml
  nodes/  nodes/tests/
  walks/
  specs/
  utils/

Next steps:
  /ambler-walk   — create your first walk
  /ambler-node   — create a standalone node
```
