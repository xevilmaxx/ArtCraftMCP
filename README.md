# ArtCraftMCP — OpenCode (opencode / opencode-go) + ArtCraft softwares over MCP

Use the OpenCode AI agent to control ArtCraft desktop apps (WordCraft, VectorCraft, SolidCraft, … — 16 apps total) via the **Model Context Protocol (MCP)**.

This repo contains:

| File | Purpose |
| ---- | ------- |
| `opencode.json` | Portable OpenCode config registering all 16 ArtCraft CLIs as `local` MCP servers with `--allow-path "."` (no hardcoded username). Copy it per-project or install it globally. |
| `install-opencode-config.bat` | One-click Windows installer: copies `opencode.json` to the current user's global OpenCode config (`%USERPROFILE%\.config\opencode\opencode.json`), backs up the old one, verifies with `opencode mcp list`, kills stale `opencode.exe` processes and relaunches OpenCode. |

## 1. How it works — who finds who?

MCP is client/server:

- **OpenCode = MCP Client (Host).** It owns the tools and needs to know where each server lives.
- **Each ArtCraft app = MCP Server.** Each `*-cli.exe` exposes `mcp` over stdio (headless, or bridged to the running app).

So **OpenCode finds WordCraft** (not the other way around). You declare each server in `opencode.json` under `mcp.servers`, then OpenCode spawns e.g.:

```text
"C:\Program Files\WordCraft\wordcraft-cli.exe" mcp --allow-path "."
```

and auto-discovers that app's tools (convert, run commands, save/export, …).

There is **no built-in autodiscovery scanner** for vendor CLIs in OpenCode — every app is declared explicitly. All ArtCraft CLIs share the same architecture (`<app>-cli.exe mcp`), so the pattern repeats 16 times.

Minimal single-app example (WordCraft only):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "wordcraft": {
        "type": "local",
        "command": [
          "C:\\Program Files\\WordCraft\\wordcraft-cli.exe",
          "mcp"
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

`✓ wordcraft connected` = working. `✗ wordcraft failed` = wrong path / app not installed / stale config (see §5).

## 2. Prerequisites

1. **OpenCode installed and on `PATH`.**
   ```bat
   opencode --version
   ```
   Must print a version. If not, install OpenCode first, then **fully restart your IDE/terminal** so the new `PATH` is picked up.
2. **ArtCraft apps installed.** Default paths assumed by `opencode.json`:
   `C:\Program Files\<App>\<cli>.exe` (see table in §4). If your launcher installed elsewhere (e.g. `%LOCALAPPDATA%\…`), edit the `command` paths accordingly.
3. **Windows.** Paths below use `%USERPROFILE%\.config\opencode\opencode.json` ( = `~/.config/opencode/opencode.json`, the documented OpenCode **global** config location). Per-project `opencode.json` in the repo root works too and overrides global (configs are merged, project wins on conflict).

## 3. Quick start

### Option A — global install (recommended, current user, no username hardcoded)

Double-click or run:

```bat
install-opencode-config.bat
```

What it does:

1. Takes `opencode.json` sitting next to the `.bat` (this repo's file, portable — it uses `"--allow-path", "."`, so there is no `C:\Users\<you>` inside).
2. Creates `%USERPROFILE%\.config\opencode\` if missing.
3. Backs up any existing global config to `opencode.json.bak`, then copies the repo file to `%USERPROFILE%\.config\opencode\opencode.json`.
4. Checks `opencode` is on `PATH`, runs `opencode mcp list` to verify, kills stale `opencode.exe`, waits 2 s, and `start`s a fresh OpenCode TUI.

Re-run the `.bat` after pulling this repo — it refreshes the global config and relaunches OpenCode.

> The original machine-specific config lived at `C:\Users\<You>\opencode.json`. That path is **not** used anymore. The `.bat` resolves the current user at runtime via `%USERPROFILE%`, so the placeholder `<You>` is never needed.

### Option B — per-project install

Copy `opencode.json` into your project root (next to `.git`, or wherever you launch `opencode` from). OpenCode loads `opencode.json` by walking up from cwd to the nearest git root. Restart OpenCode / run `opencode mcp list`.

### Option C — manual

```bat
mkdir "%USERPROFILE%\.config\opencode"
copy /Y opencode.json "%USERPROFILE%\.config\opencode\opencode.json"
opencode mcp list
```

## 4. All 16 apps registered in `opencode.json`

Every entry is `{"type": "local", "command": ["<exe>", "mcp", "--allow-path", "."]}`.

| # | MCP name | Executable (default) |
| - | -------- | -------------------- |
| 1 | `wordcraft` | `C:\Program Files\WordCraft\wordcraft-cli.exe` |
| 2 | `vectorcraft` | `C:\Program Files\VectorCraft\vectorcraft-cli.exe` |
| 3 | `solidcraft` | `C:\Program Files\SolidCraft\solidcraft-cli.exe` |
| 4 | `photocraft` | `C:\Program Files\PhotoCraft\photocraft-cli.exe` |
| 5 | `gridcraft` | `C:\Program Files\GridCraft\gridcraft-cli.exe` |
| 6 | `deckcraft` | `C:\Program Files\DeckCraft\deckcraft-cli.exe` |
| 7 | `pdfcraft` | `C:\Program Files\PdfCraft\pdfcraft-cli.exe` |
| 8 | `filmcraft` | `C:\Program Files\FilmCraft\filmcraft-cli.exe` |
| 9 | `lightcraft` | `C:\Program Files\LightCraft\lightcraft-cli.exe` |
| 10 | `effectcraft` | `C:\Program Files\EffectCraft\effectcraft-cli.exe` |
| 11 | `designcraft` | `C:\Program Files\DesignCraft\designcraft-cli.exe` |
| 12 | `figcraft` | `C:\Program Files\FigCraft\figcraft-cli.exe` |
| 13 | `soundcraft` | `C:\Program Files\SoundCraft\soundcraft-cli.exe` |
| 14 | `cadcraft` | `C:\Program Files\CADCraft\cadcraft-cli.exe` |
| 15 | `texturecraft` | `C:\Program Files\TextureCraft\texturecraft-cli.exe` |
| 16 | `craftanything` | `C:\Program Files\Craft Anything\craft-anything-cli.exe` |

Notes:

- Names with spaces/casing (`CADCraft`, `Craft Anything` / `craft-anything-cli.exe`) must match disk exactly. If `opencode mcp list` fails for exactly one server, check that path first with `"C:\…\*-cli.exe" --help`.
- Uninstalled apps will show as failed — that is expected. Either install the app or delete its block from your copy of `opencode.json`.
- Extra keys from the official schema (`cwd`, `environment`, `enabled`, `timeout`) are optional and omitted here for brevity.

## 5. `--allow-path`: sandbox, `.`, subfolders, "everywhere"

Each headless MCP server runs **sandboxed**: it may only read/write files under explicitly allowed roots. Without an allowed root you get errors like:

```text
Design was unsaved in memory (dirty:true, path:null).
Save to Downloads is blocked: allowed folders are only recovery + …\Temp\solidcraft-mcp-… .
Saved to C:\Users\<You>\AppData\Local\Temp\solidcraft-mcp-…\solidplatetest_opencode.sc (9033 bytes).
To get it in Downloads, add --allow-path dir to this server in your MCP client config, e.g.:
solidcraft --allow-path C:\Users\<You>\Downloads
```

`--allow-path` is **shared across all ArtCraft CLIs** (not SolidCraft-only). Append it per server:

```json
{
  "mcp": {
    "servers": {
      "solidcraft": {
        "type": "local",
        "command": [
          "C:\\Program Files\\SolidCraft\\solidcraft-cli.exe",
          "mcp",
          "--allow-path",
          "C:\\Users\\<You>"
        ]
      }
    }
  }
}
```

Common scopes:

| Goal | `--allow-path` value |
| ---- | -------------------- |
| One folder (e.g. Downloads) | `"C:\\Users\\<You>\\Downloads"` |
| Whole profile (Downloads + Documents + repos, recommended over full disk) | `"C:\\Users\\<You>"` |
| Entire drive ("everywhere", removes sandbox isolation) | `"C:\\"` |
| **Current OpenCode working dir (this repo's choice, portable)** | `"."` |
| Several distinct roots | repeat the flag: `"mcp", "--allow-path", "D:\\work", "--allow-path", "C:\\shared"` |

Why `"."`:

- No hardcoded username → same file works for every user and every checkout.
- Resolves to **wherever you launched OpenCode** (the spawned server inherits cwd).
- **Covers subfolders recursively**: `.\projects\designs\part1.sc`, `.\output\exports\doc.pdf` are descendants of `.` and permitted.
- Moving to another project folder automatically re-scopes permissions — no config rewrite.

WordCraft additionally supports `--automation-read-root` / `--automation-write-root` to confine open/save/mail-merge/template dirs (same idea, finer split than the single `--allow-path` gate). Both accept `.` the same way.

> Security: broadening to `C:\Users\<You>` or `C:\` lets AI-driven commands read/write anywhere in that scope. Prefer `"."` (least privilege) unless you truly need cross-folder saves.

## 6. Troubleshooting (from real session log)

### 6.1 `{"program":"opencode","reason":"not_found"}` / Craft Anything 0.2.0 failure log

Full symptom (2026-11-02):

```text
Craft Anything 0.2.0 failure log
What: OpenCode (OpenCode)
Error: opencode isn't installed or isn't on your PATH.
Working folder: C:\Users\<You>\source\repos\Godot_4_7_to_Rust
opencode run --auto '[your message, 4961 characters]'
```

Fix:

1. `opencode --version` in a **new** terminal. If "not recognized" → install OpenCode / fix `PATH` (dir containing `opencode.exe` must be in system `PATH`).
2. If it works in terminal but not in the editor/extension → **restart the IDE** (VS Code / Visual Studio / Craft Anything host) so it inherits the updated environment.
3. Check extension settings for an explicit opencode binary path field and fill the absolute path if needed.

### 6.2 `✗ wordcraft failed: 'wordcraft-mcp-executable' is not recognized…`

You pasted a placeholder (`wordcraft-mcp-executable`) from docs. Windows has no such binary. Replace `command` with the real absolute path:

- exe: `["C:\\Program Files\\WordCraft\\wordcraft-cli.exe", "mcp"]`
- Node: `["cmd.exe", "/c", "npx", "-y", "@wordcraft/mcp-server"]`
- Python module: `["python", "-m", "wordcraft.mcp"]`

Paths with spaces must be separate JSON array elements (shown above) — do not jam them into one string.

Prob­ing the real CLI first helps:

```bat
"C:\Program Files\WordCraft\wordcraft-cli.exe" --help
"C:\Program Files\WordCraft\wordcraft-cli.exe" mcp --help
```

`wordcraft-cli` supports `convert <in> <out>`, `info`, `text`, `inspect`, `render`, `run --cmd …`, `commands`, `mcp [--connect HOST:PORT | --author NAME] [--automation-read-root DIR] [--automation-write-root DIR]`, `zotero`, `--version`, plus `--password` / `WORDCRAFT_REGION` handling — every ArtCraft CLI mirrors this shape.

### 6.3 Saves land in `Temp`, Downloads blocked

See §5: add `--allow-path` for the destination (or `"."` and launch OpenCode in the destination's parent). Then **restart/reload OpenCode** (`opencode mcp list`) — flag changes require a server respawn.

### 6.4 Count check

The full file in this repo holds **16** `mcp.servers` entries (wordcraft, vectorcraft, solidcraft, photocraft, gridcraft, deckcraft, pdfcraft, filmcraft, lightcraft, effectcraft, designcraft, figcraft, soundcraft, cadcraft, texturecraft, craftanything). If your copy shows fewer, re-copy from this repo or re-run the `.bat`.

## 7. Usage examples

```bat
opencode
opencode mcp list
opencode run "Export the current VectorCraft canvas to SVG"
opencode run --quiet "Parse input vectors from build/out.svg and feed coordinates to the cutting engine RPC on localhost:9000"
```

WordCraft headless example (no MCP):

```bat
"C:\Program Files\WordCraft\wordcraft-cli.exe" run --file doc.docx --cmd "caret.docEnd" --save out.docx --print
```

## 8. References

- OpenCode config locations & precedence: global `~/.config/opencode/opencode.json` (`%USERPROFILE%\.config\opencode\opencode.json` on Windows), project `opencode.json`, `OPENCODE_CONFIG` / `OPENCODE_CONFIG_CONTENT` overrides — merged, project wins. Schema: `https://opencode.ai/config.json`.
- MCP servers: `type: "local"` + `command: [...]`, optional `cwd` / `environment` / `enabled` / `timeout`; `type: "remote"` + `url` + `headers`/`oauth`.
- This README distills a Gemini troubleshooting conversation (PATH fix, placeholder-exe fix, 14→16 app expansion incl. SolidCraft, `--allow-path` scoping to `.`/profile/drive, subfolder recursion).
