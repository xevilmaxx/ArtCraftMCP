# ArtCraftMCP — OpenCode (opencode / opencode-go) + ArtCraft softwares over MCP

Control ArtCraft desktop apps with the OpenCode AI agent via the **Model Context Protocol (MCP)**.

This repo contains:

| File | Purpose |
| ---- | ------- |
| `opencode.json` | Portable OpenCode template registering the **13 actually installed** ArtCraft CLIs as `local` MCP servers, each with its **own correct sandbox flags** (no hardcoded username — roots are `"."`). |
| `install-opencode-config.bat` | One-click Windows installer. **Merges** the template into the current user's global config (`%USERPROFILE%\.config\opencode\opencode.json`), writes a timestamped `.bak` first, then verifies with `opencode mcp list` and relaunches OpenCode. |
| `merge-opencode-config.ps1` | Helper the `.bat` calls. Copies every repo `mcp.servers` entry over (add or replace), **keeps** anything already global but absent from the repo (e.g. your `blender` server, `model`/`small_model`), refuses to touch invalid JSON. |

## 1. How it works — who finds who?

MCP is client/server:

- **OpenCode = MCP Client (Host).** It owns the tools and must be told where each server lives.
- **Each ArtCraft app = MCP Server.** Each `*-cli.exe` exposes `mcp` over stdio (headless, or bridged to the running app).

So **OpenCode finds WordCraft** (not the other way around). You declare each server under `mcp.servers` in `opencode.json`; OpenCode spawns it and auto-discovers its tools.

There is **no autodiscovery scanner** for vendor CLIs — every app is declared explicitly. The trap this repo fell into earlier: assuming all 16 ArtCraft CLIs share one flag (`--allow-path`). They do not. Each CLI has its own `mcp` usage (verified on 2026-11-02 against the real `--help` of every installed exe — see §4).

Minimal single-app example (WordCraft, correct flags):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "wordcraft": {
        "type": "local",
        "command": [
          "C:\\Program Files\\WordCraft\\wordcraft-cli.exe",
          "mcp",
          "--automation-read-root",
          ".",
          "--automation-write-root",
          "."
        ]
      }
    }
  }
}
```

Verify any time with:

```bat
opencode mcp list
```

`✓ wordcraft connected` = working. `✗ wordcraft failed` = wrong flags / wrong path / app not installed / stale config (see §6).

## 2. Prerequisites

1. **OpenCode installed and on `PATH`.**
   ```bat
   opencode --version
   ```
   Must print a version. If not, install OpenCode first, then **fully restart your IDE/terminal** so the new `PATH` is picked up.
2. **ArtCraft apps installed.** Default paths assumed: `C:\Program Files\<App>\<cli>.exe` (see table in §4). Only the 13 apps below were found on this machine — `CADCraft`, `DesignCraft`, `FigCraft` have no folders/exes and are intentionally **absent** from the template; `solvecraft-cli.exe` exists but prints "deprecated, use solidcraft-cli" and is also omitted.
3. **Windows.** Global config lives at `%USERPROFILE%\.config\opencode\opencode.json` (= `~/.config/opencode/opencode.json`, the documented OpenCode **global** location). A per-project `opencode.json` in the repo root also works and overrides global (configs are merged, project wins on conflict).

## 3. Quick start

### Option A — global install (recommended)

Double-click or run:

```bat
install-opencode-config.bat
```

What it does:

1. Takes `opencode.json` next to the `.bat` (portable — roots are `"."`, so there is no `C:\Users\<You>` inside).
2. Creates `%USERPROFILE%\.config\opencode\` if missing.
3. Backs up the existing global file to `opencode.json.<yyyyMMdd-HHmmss>.bak`, then **merges**: every repo server is added/updated, everything else global (`blender`, `model`, `small_model`, …) is kept.
4. Runs `opencode mcp list`, kills stale `opencode.exe`, waits 2 s, starts a fresh OpenCode TUI.

Re-run after pulling this repo — it refreshes the ArtCraft servers and relaunches OpenCode. Your `blender` entry and model settings survive.

> The original machine-specific path `C:\Users\<You>\opencode.json` is **not** used. The `.bat` resolves the current user at runtime via `%USERPROFILE%`, so the placeholder `<You>` is never needed.

### Option B — per-project install

Copy `opencode.json` into your project root (where you launch `opencode` from). OpenCode loads it by walking up from cwd to the nearest git root. Restart OpenCode / run `opencode mcp list`.

### Option C — manual (same merge, no `.bat`)

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File merge-opencode-config.ps1 -Repo opencode.json -GlobalPath "%USERPROFILE%\.config\opencode\opencode.json"
opencode mcp list
```

## 4. The real flags — per app (this was the bug)

`--allow-path` works on **SolidCraft only**. Every other CLI rejected it with `unknown mcp option '--allow-path'` / `unexpected argument '--allow-path'` (verbatim from `opencode mcp list` before the fix). The table below is the corrected template, each row verified against that exe's real `mcp --help` plus a spawn probe (empty-stdin: `rc=0` + "files confined" banner, or `rc=1` + "MCP init: connection closed" — both mean **flags accepted**, the server is waiting for MCP init; `rc=1/2` + "unknown option" meant rejected).

| MCP name | Executable | Correct `command` tail after the exe | Flag family |
| -------- | ---------- | ------------------------------------ | ----------- |
| `wordcraft` | `C:\Program Files\WordCraft\wordcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| `vectorcraft` | `C:\Program Files\VectorCraft\vectorcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| `solidcraft` | `C:\Program Files\SolidCraft\solidcraft-cli.exe` | `mcp --allow-path .` | **allow-path (only here)** |
| `photocraft` | `C:\Program Files\PhotoCraft\photocraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| `gridcraft` | `C:\Program Files\GridCraft\gridcraft-cli.exe` | `mcp` (bare — no root flags exist; `mcp [--connect PORT] [--in FILE \| --sample NAME]`) | bare |
| `deckcraft` | `C:\Program Files\DeckCraft\deckcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| `pdfcraft` | `C:\Program Files\PdfCraft\pdfcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots (`--root/--compact` also exist, not needed) |
| `filmcraft` | `C:\Program Files\FilmCraft\filmcraft-cli.exe` | `mcp` (bare — headless or `--bridge` to live app) | bare |
| `lightcraft` | `C:\Program Files\LightCraft\lightcraft-cli.exe` | `mcp` (bare — `--connect/--demo/--library/--compact` are session selectors, not sandbox roots) | bare |
| `effectcraft` | `C:\Program Files\EffectCraft\effectcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots (`--autosave/--bridge` are alternates) |
| `soundcraft` | `C:\Program Files\SoundCraft\soundcraft-cli.exe` | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| `texturecraft` | `C:\Program Files\TextureCraft\texturecraft-cli.exe` | `mcp --read-root . --write-root .` | ⚠️ short form, **no** `automation-` prefix |
| `craftanything` | `C:\Program Files\Craft Anything\craft-anything-cli.exe` | `mcp` (bare — its options are `--allow-run/--deep/--project/…`, none is a path root; `--allow-run` means "let tools run code", not "let them read this folder") | bare |

Reference `mcp` usage lines as printed by the exes:

- wordcraft: `mcp [--connect HOST:PORT | --author NAME] [--automation-read-root DIR] [--automation-write-root DIR]`
- vectorcraft: `mcp [--connect ADDR | --headless] [--automation-read-root DIR]... [--automation-write-root DIR]...`
- solidcraft: `mcp [--headless] [--in design.sc|script.json] [--connect 127.0.0.1:PORT [--token T]] [--allow-path DIR]... [--allow-any-path] ...`
- photocraft: `mcp [OPTIONS]` + `--bridge/--control-token[-file]/--automation-read-root/--automation-write-root`
- gridcraft: `mcp [--connect PORT] [--in FILE | --sample NAME]`
- deckcraft: `mcp [--connect PORT] [--sample] [--automation-read-root DIR]... [--automation-write-root DIR]...`
- pdfcraft: `mcp [--root DIR] [--compact] [--automation-read-root DIR] [--automation-write-root DIR]`
- filmcraft: `mcp` (headless, or `--bridge` to the live app)
- lightcraft: `mcp [OPTIONS] [FILES/FOLDERS…]` (`--connect/--demo/--library/--compact`)
- effectcraft: `mcp [--autosave | --bridge PORT] [--automation-read-root DIR] [--automation-write-root DIR]`
- soundcraft: `mcp [OPTIONS]` (`--connect/--demo/--automation-read-root/--automation-write-root`)
- texturecraft: `mcp [--bridge <port>] [--token <token>] [--read-root <dir>] [--write-root <dir>]`
- craft-anything: `mcp [OPTIONS]` (`--all-tools/--format/--inbox/--project/--allow-run/--deep/--clean-room`)

Not in the template and why: `cadcraft`, `designcraft`, `figcraft` — no `C:\Program Files\<App>\` folder and no `*-cli.exe` anywhere (checked `C:\Program Files`, `Program Files (x86)`, `%LOCALAPPDATA%`, `%APPDATA%`). Re-add a block if you install the app later, using whatever its own `mcp --help` prints. `solvecraft-cli.exe` exists but is deprecated in favor of `solidcraft-cli` — no entry needed.

## 5. Sandbox roots: what `"."` means

Each headless MCP server is **sandboxed**: with no root it reads/writes nothing project-related (earlier symptom: SolidCraft saves landing in `Temp\solidcraft-mcp-…` with "Save to Downloads is blocked"). Roots open the gate per direction; repeat the flag for several folders:

- `--automation-read-root DIR` / `--automation-write-root DIR` (most apps): confine what the agent's commands may read (open, place, relink, mail-merge data, fonts, …) and write (save, export, …) to `DIR`, links followed. Omit a side → that side is denied. Applies to the headless server; refused with `--connect/--bridge` (a running app enforces its own roots).
- `--read-root` / `--write-root` (texturecraft only): same idea, shorter names.
- `--allow-path DIR`, repeatable (solidcraft only; plus `--allow-any-path` for everywhere).
- bare `mcp` (gridcraft, filmcraft, lightcraft, craft-anything): these CLIs expose **no** root flags on `mcp` — file scope is governed by session selectors (`--in/--sample/--library/--project`) or not at all. Passing `--allow-path` to them is what produced every `✗ failed` line before the fix.

Why the template uses `"."`:

- No hardcoded username → same file works for every user and checkout.
- Resolves to **wherever you launched OpenCode** (the server inherits cwd; probes confirm `read root C:\Users\<You>\source\repos\ArtCraftMCP` when launched there).
- **Covers subfolders recursively**: `.\projects\designs\part1.sc`, `.\output\exports\doc.pdf` are descendants of `.` and permitted.
- Moving to another project folder automatically re-scopes permissions — no config rewrite.

Broader scopes (replace `"."` on the servers you want to widen): one folder (`--automation-read-root C:\Users\<You>\Downloads …`), whole profile (`C:\Users\<You>`), entire drive (`C:\`, removes isolation — prefer `"."` / least privilege).

## 6. Troubleshooting (from the real session log)

### 6.1 `{"program":"opencode","reason":"not_found"}` / Craft Anything 0.2.0 failure log

```text
Craft Anything 0.2.0 failure log — What: OpenCode (OpenCode)
Error: opencode isn't installed or isn't on your PATH.
Working folder: C:\Users\<You>\source\repos\Godot_4_7_to_Rust
```

Fix: `opencode --version` in a **new** terminal. "Not recognized" → install OpenCode / add its dir to system `PATH`. Works in terminal but not in the editor/extension → **restart the IDE** (VS Code / Visual Studio / Craft Anything host). Check extension settings for an explicit opencode binary path field if it has one.

### 6.2 `✗ wordcraft failed: 'wordcraft-mcp-executable' is not recognized…`

You pasted a placeholder from docs. Windows has no such binary — point `command` at the real absolute path (`["C:\\Program Files\\WordCraft\\wordcraft-cli.exe", "mcp", …]`). Paths with spaces stay as separate JSON array elements.

### 6.3 Every server `failed` after adding `--allow-path` (the bug this rewrite fixes)

Before:

```text
✗ craftanything  failed: ... error: unexpected argument '--allow-path' found
  tip: a similar argument exists: '--allow-run'
✗ deckcraft      failed: ... deckcraft-cli: unknown mcp option `--allow-path`
✗ vectorcraft    failed: ... vectorcraft-cli: unknown mcp option `--allow-path`
✗ wordcraft      failed: ... wordcraft-cli: mcp: unknown option --allow-path
✗ texturecraft   failed: ... [--read-root <dir>] [--write-root <dir>]
✓ solidcraft     connected
✗ cadcraft / designcraft / figcraft failed: The system cannot find the path specified.
```

Meaning: `--allow-path` is SolidCraft-only (hence the lone `✓ solidcraft`); `craft-anything --allow-run` is unrelated (code-execution consent, not a path gate); texturecraft wants `--read-root/--write-root`; cad/design/fig exes don't exist. Fix = this repo's corrected `opencode.json` + re-run the `.bat`, then `opencode mcp list` should show `✓` on all installed apps.

### 6.4 Saves land in `Temp`, Downloads blocked

```text
Design was unsaved in memory (dirty:true, path:null).
Save to Downloads is blocked: allowed folders are only recovery + …\Temp\solidcraft-mcp-… .
```

Add the destination as a root for that server (or launch OpenCode in the destination's parent when roots are `"."`). Root-flag changes require a server respawn — re-run the `.bat` or restart OpenCode.

### 6.5 My `blender` server / model disappeared after installing

Old `.bat` **overwrote** the global file. The new `.bat` + `merge-opencode-config.ps1` **merge** instead (repo servers upserted, everything else kept, timestamped `.bak` first). If you ran the old script, restore from the `.bak` beside your global config, then run the new `.bat`.

## 7. Usage examples

```bat
opencode
opencode mcp list
opencode run "Export the current VectorCraft canvas to SVG"
opencode run --quiet "Parse input vectors from build/out.svg and feed coordinates to the cutting engine RPC on localhost:9000"
```

WordCraft headless (no MCP):

```bat
"C:\Program Files\WordCraft\wordcraft-cli.exe" run --file doc.docx --cmd "caret.docEnd" --save out.docx --print
```

## 8. References

- OpenCode config locations & precedence: global `~/.config/opencode/opencode.json` (`%USERPROFILE%\.config\opencode\opencode.json` on Windows), project `opencode.json`, `OPENCODE_CONFIG` / `OPENCODE_CONFIG_CONTENT` overrides — merged, project wins. Schema: `https://opencode.ai/config.json`.
- MCP servers: `type: "local"` + `command: [...]`, optional `cwd` / `environment` / `enabled` / `timeout`; `type: "remote"` + `url` + `headers`/`oauth`.
- This README distills a Gemini troubleshooting thread (PATH fix, placeholder-exe fix, 14→16-app expansion, `--allow-path` scoping to `.`/profile/drive) **corrected against the ground truth**: each installed exe's actual `mcp --help` output and a spawn probe of every template entry on 2026-11-02. The Gemini claim "`--allow-path` is shared across all ArtCraft CLIs" is wrong — §4 is authoritative.
