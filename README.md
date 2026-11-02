# ArtCraftMCP

> Drive your ArtCraft desktop apps with the OpenCode AI agent — over MCP.

[![Windows](https://img.shields.io/badge/Windows-%E2%80%93-blue)](https://github.com/storytold)
[![OpenCode](https://img.shields.io/badge/OpenCode-MCP_Client-purple)](https://opencode.ai/docs/mcp-servers/)
[![Config](https://img.shields.io/badge/config-1--tab_indent-green)]()
[![Servers](https://img.shields.io/badge/servers-16_in_template-brightgreen)]()

**New here?** Install in under a minute: double-click `install-opencode-config.bat`, then run `opencode mcp list`. Every app installed on your machine should show green (14 here: 13 ArtCraft + blender). Entries for apps you don't have installed show `failed: system cannot find the path specified` — install the app or delete its block. Details in [troubleshooting](#troubleshooting).

---

## What this is

OpenCode is an AI coding agent. ArtCraft apps (WordCraft, VectorCraft, SolidCraft…) each ship a headless CLI that can act as a **Model Context Protocol (MCP) server**. This repo wires them together: one portable `opencode.json` covering **all 16 suite apps** as OpenCode tools, plus a one-click installer that discovers which ones exist on your machine and merges only those into your personal config.

```mermaid
flowchart TB
    You(["You"]) --> OC["OpenCode agent\nMCP client and host"]

    %% ---- where the config comes from ----
    subgraph Repo["This repo - portable template"]
        direction TB
        TPL["opencode.json\nall 16 ArtCraft servers\n1-tab indent, '.' roots\nno usernames inside"]
        BAT["install-opencode-config.bat\n1 - back up global config\n2 - merge template\n3 - relaunch OpenCode"]
        PS1["merge-opencode-config.ps1\nupsert repo servers\nkeep blender, model, small_model\ntimestamped .bak first"]
    end

    TPL --> PS1
    BAT --> PS1

    subgraph Machine["Your machine - global config"]
        GLB["USERPROFILE/.config/opencode/opencode.json\nblender kept, models kept\ninstalled ones merged, missing skipped"]
    end

    PS1 --> GLB
    GLB --> OC

    %% ---- what OpenCode launches ----
    OC -- "spawns over stdio, JSON-RPC" --> AUTO
    OC -- "spawns over stdio" --> SOLO
    OC -- "spawns over stdio" --> BARE
    OC -- "leaves untouched" --> KEPT
    OC -. "optional: drive the live app" .-> LIVE

    subgraph AUTO["Automation roots: --automation-read-root . --automation-write-root ."]
        direction LR
        W["wordcraft-cli"] ~~~ V["vectorcraft-cli"] ~~~ PH["photocraft-cli"] ~~~ D["deckcraft-cli"]
        PDF["pdfcraft-cli"] ~~~ EF["effectcraft-cli"] ~~~ SO["soundcraft-cli"]
        CAD["cadcraft-cli\nflags guessed"] ~~~ DES["designcraft-cli\nflags guessed"] ~~~ FIG["figcraft-cli\nflags guessed"]
    end

    subgraph SOLO["Own flag dialects"]
        direction LR
        SL["solidcraft-cli\n--allow-path ."]
        TX["texturecraft-cli\n--read-root . --write-root ."]
    end

    subgraph BARE["Bare mcp - no root flags on these CLIs"]
        direction LR
        GR["gridcraft-cli"] ~~~ FI["filmcraft-cli"] ~~~ LI["lightcraft-cli"] ~~~ CA["craft-anything-cli"]
    end

    subgraph KEPT["Kept as-is by the merger"]
        BL["blender via uvx mcp-for-blender"]
    end

    LIVE["Live app bridge\n--connect / --bridge\nthe running app enforces its own roots"]

    %% ---- what the servers touch ----
    AUTO -- "reads and writes, gated by roots" --> Files
    SOLO -- "reads and writes, gated by roots" --> Files
    BARE -- "session-scoped files only" --> Files

    Files["Your project files\n. = folder where OpenCode launched\nsubfolders included"]

    Files -- "tool results flow back" --> OC
    OC -- "opencode mcp list" --> OK["14 connected"]
```

In short: **OpenCode finds your apps** — not the other way around. Each entry in `opencode.json` tells OpenCode which executable to launch and which folders it may touch.

---

## What's in this repo

| File | What it does |
| ---- | ------------ |
| `opencode.json` | The portable template — all 16 ArtCraft servers, each with its own sandbox flags, `"."` roots, no hardcoded username. |
| `install-opencode-config.bat` | One-click installer. Discovers installed apps, merges them into your global config, backs it up first, then relaunches OpenCode. |
| `merge-opencode-config.ps1` | The merge engine behind the `.bat`. Installs only servers whose exe exists on disk, skips the rest, keeps everything else you already had. |

All JSON in this repo uses **1-tab indentation** as standard — including everything the merger writes.

---

## Quick start

### Option A — one click (recommended)

1. Double-click **`install-opencode-config.bat`**.
2. It backs up your current global config (`opencode.json.<date>.bak`), discovers which suite exes exist (13 of 16 on this machine), merges those in, and restarts OpenCode.
3. Run `opencode mcp list` — every installed app should be green:

```text
✓ blender        connected
✓ craftanything  connected
✓ deckcraft      connected
✓ effectcraft    connected
✓ filmcraft      connected
✓ gridcraft      connected
✓ lightcraft     connected
✓ pdfcraft       connected
✓ photocraft     connected
✓ solidcraft     connected
✓ soundcraft     connected
✓ texturecraft   connected
✓ vectorcraft    connected
✓ wordcraft      connected
```

Your existing setup is safe: the merger **keeps** entries it doesn't know about (like `blender`) and your `model` / `small_model` choices. It only adds or refreshes ArtCraft servers whose exe is actually installed — the rest are reported as skipped and left untouched. Servers for apps you never installed show `✗ failed: system cannot find the path specified`; either install the app or delete its block from your copy.

### Option B — per project

Copy `opencode.json` into your project folder (where you launch `opencode` from). Project config overrides global where they overlap.

### Option C — manual merge

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File merge-opencode-config.ps1 -Repo opencode.json -GlobalPath "%USERPROFILE%\.config\opencode\opencode.json"
opencode mcp list
```

---

## Prerequisites

- **OpenCode installed and on `PATH`.** Check with `opencode --version` in a fresh terminal. If it works there but not in your editor, **restart the editor** so it picks up the new `PATH`.
- **ArtCraft apps installed** under `C:\Program Files\<App>\`. The template covers all 16 suite apps; on this machine `CADCraft`, `DesignCraft` and `FigCraft` aren't installed, so the installer skips those three entries.
- **Windows.** Your global config lives at `%USERPROFILE%\.config\opencode\opencode.json`.

---

## Compatibility matrix

Every ArtCraft CLI exposes `mcp`, but each one guards file access with **different flags**. Using the wrong flag is the #1 cause of `✗ failed` lines — 13 entries below were verified against that exe's real `mcp --help` output; the last 3 use the most common flag family as a best guess (those apps aren't installed here) and are marked accordingly.

| App | Command tail | Flag family |
| --- | ------------ | ----------- |
| wordcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| vectorcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| solidcraft | `mcp --allow-path .` | `--allow-path` (**only SolidCraft**) |
| photocraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| gridcraft | `mcp` | bare — no root flags exist |
| deckcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| pdfcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| filmcraft | `mcp` | bare — headless or `--bridge` |
| lightcraft | `mcp` | bare — session flags only |
| effectcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| soundcraft | `mcp --automation-read-root . --automation-write-root .` | automation roots |
| texturecraft | `mcp --read-root . --write-root .` | short form, **no** `automation-` prefix |
| craftanything | `mcp` | bare — `--allow-run` is code-execution consent, not a path gate |
| cadcraft | `mcp --automation-read-root . --automation-write-root .` | guessed, unverified — app not installed here |
| designcraft | `mcp --automation-read-root . --automation-write-root .` | guessed, unverified — app not installed here |
| figcraft | `mcp --automation-read-root . --automation-write-root .` | guessed, unverified — app not installed here |

If you install one of those three, confirm its flags first with `"C:\Program Files\<App>\<cli>.exe" mcp --help` and correct the template if they differ — then re-run the installer. (`solvecraft-cli.exe` exists on disk but prints "deprecated, use solidcraft-cli", so it has no entry.)

---

## File access, simply explained

Each headless server is **sandboxed**: with no root flag it can't read or write your project files (symptom: SolidCraft saves landing in `Temp\solidcraft-mcp-…` with "Save to Downloads is blocked"). The template grants access with `"."`:

- **Portable** — no `C:\Users\<You>` inside, works for every user and checkout.
- **Follows you** — `"."` means "wherever you launched OpenCode".
- **Recursive** — subfolders like `.\projects\designs\part1.sc` are covered.
- **Repeatable** — most CLIs accept the flag more than once for several folders.

Need wider access? Replace `"."` with an absolute folder on the servers you want to widen. Prefer the smallest scope that works.

---

## Usage

```bat
opencode
opencode mcp list
opencode run "Export the current VectorCraft canvas to SVG"
opencode run --quiet "Parse input vectors from build/out.svg and feed coordinates to the cutting engine RPC on localhost:9000"
```

Headless, without MCP:

```bat
"C:\Program Files\WordCraft\wordcraft-cli.exe" run --file doc.docx --cmd "caret.docEnd" --save out.docx --print
```

---

## Troubleshooting

<details>
<summary><strong><code>opencode isn't installed or isn't on your PATH</code></strong></summary>

Run `opencode --version` in a **new** terminal. "Not recognized" means OpenCode isn't installed or its folder isn't in system `PATH`. If it works in a terminal but not inside your editor or the Craft Anything extension, **restart the IDE** — it inherited the old environment. Some extensions also have a setting for the explicit opencode binary path.

</details>

<details>
<summary><strong><code>'wordcraft-mcp-executable' is not recognized…</code></strong></summary>

That name is a placeholder from generic docs — no such binary exists. Point `command` at the real exe, e.g. `["C:\Program Files\WordCraft\wordcraft-cli.exe", "mcp", …]`. Keep each argument as its own JSON array element, especially paths with spaces.

</details>

<details>
<summary><strong>Every server shows <code>✗ failed … unknown option '--allow-path'</code></strong></summary>

`--allow-path` is SolidCraft-only. The other CLIs reject it (craft-anything even suggests `--allow-run`, which is unrelated — it gates code execution, not folders). Fix: use this repo's `opencode.json`, which carries the per-app flags from the [matrix](#compatibility-matrix), re-run the installer, then `opencode mcp list`.

</details>

<details>
<summary><strong>Saves land in <code>Temp</code>, destination "blocked"</strong></summary>

The server's sandbox doesn't include your destination. Either launch OpenCode in the destination's parent (roots are `"."`), or add that folder as a root flag for the server, then restart OpenCode so the server respawns with the new flags.

</details>

<details>
<summary><strong>Port already in use (<code>opencode mcp list</code>, <code>opencode reload</code>) / shows nothing</strong></summary>

A stale `opencode` background service is holding managed-service port 28894, so any command needing the service fails with `Failed to start server. Is port 28894 in use?`. Right after killing it, the first command may briefly say `No MCP servers configured` while the service reboots — just run it again. Find the squatter and stop just that process:

```bat
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 28894 | Select-Object OwningProcess"
taskkill /F /PID <that-number>
opencode mcp list
```

</details>

<details>
<summary><strong><code>✗ failed: The system cannot find the path specified</code></strong></summary>

That app isn't installed where the template expects (`C:\Program Files\<App>\<cli>.exe`). This is normal for `cadcraft`, `designcraft` and `figcraft` on machines without them — and for any app when you run `opencode mcp list` from inside this repo (the repo template itself lists all 16 as project config). Either install the missing app or delete its block from your copy of `opencode.json`.

</details>

<details>
<summary><strong>My <code>blender</code> server / model settings disappeared</strong></summary>

That was the old installer, which **overwrote** the global file. The current one **merges** and writes a timestamped `.bak` first. Restore from the `.bak` next to your global config, then run the new installer.

</details>

---

## References

- OpenCode config & precedence (`~/.config/opencode/opencode.json`, project `opencode.json`, `OPENCODE_CONFIG` overrides) — [opencode.ai/docs/config](https://opencode.ai/docs/config/)
- MCP servers (`type: local` + `command`, optional `cwd` / `environment` / `timeout`) — [opencode.ai/docs/mcp-servers](https://opencode.ai/docs/mcp-servers/)
- The `--allow-path`-everywhere claim from an earlier AI troubleshooting thread is **wrong** — 13 of the 16 [matrix](#compatibility-matrix) entries were verified exe-by-exe on 2026-11-02 (the other 3 use the most common flag family as a guess), and `opencode mcp list` reports every installed server connected.
