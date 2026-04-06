# Gas Town — Technical Summary

> **Gas Town** is a multi-agent AI orchestration system built in Go that coordinates multiple AI coding agents (Claude, Copilot, Codex, Gemini, etc.) with persistent, git-backed work tracking.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Language & Build](#-core-language--build)
3. [Data & Storage Layer](#-data--storage-layer)
4. [Agent Runtime Integration](#-agent-runtime-integration)
5. [Internal Package Map](#-internal-package-map)
6. [Terminal UI (TUI)](#️-terminal-ui-tui)
7. [Web Dashboard](#-web-dashboard)
8. [Concurrency & Process Management](#-concurrency--process-management)
9. [Observability (Telemetry)](#-observability-telemetry)
10. [Infrastructure & Packaging](#-infrastructure--packaging)
11. [Federated Networking (Wasteland)](#-federated-networking-wasteland)
12. [Testing Stack](#-testing-stack)
13. [Key Concepts & Roles](#-key-concepts--roles)
14. [Data Flow & Lifecycle](#-data-flow--lifecycle)
15. [Design Philosophy](#-design-philosophy)

---

## Architecture Overview

```
User / Human
    │
    └── gt CLI (Go + Cobra)
            │
            ├── tmux sessions ─── AI Agents (Claude, Codex, Copilot, Gemini, etc.)
            │        │                   │
            │        └── Hooks      Git worktrees (persistent state per agent)
            │
            ├── Beads (bd) ──────── Git-backed issue tracking (.beads/ in repo)
            ├── Dolt ────────────── MySQL-compatible versioned SQL DB (Wasteland federation)
            ├── SQLite ──────────── Local convoy database queries
            │
            ├── TUI (Bubbletea) ─── gt feed interactive dashboard (terminal)
            ├── Web (htmx) ──────── gt dashboard auto-refreshing browser UI
            └── OTEL ────────────── Telemetry → VictoriaMetrics / VictoriaLogs
```

### Workspace Layout

```
~/gt/                          ← Town (workspace root)
  ├── mayor/                   ← Mayor agent (global coordinator)
  ├── <rig-name>/              ← One folder per project Rig
  │     ├── crew/<name>/       ← Human dev workspace
  │     ├── polecats/<name>/   ← Worker agent checkouts
  │     │     └── hooks/       ← Git worktrees for persistent state
  │     ├── witness/           ← Per-rig health monitor agent
  │     └── refinery/          ← Per-rig merge queue processor
  └── .beads/                  ← Git-tracked issue store
```

---

## 🔧 Core Language & Build

| Technology | Version | Role |
|---|---|---|
| **Go** | `1.25+` | Primary language for all `gt` CLI and internal packages. Compiled to a single binary, strong concurrency model with goroutines. |
| **Cobra** (`spf13/cobra`) | `v1.10.2` | CLI framework powering all `gt` sub-commands — `gt sling`, `gt convoy`, `gt mayor`, `gt feed`, `gt sling`, `gt wl`, etc. |
| **Make** | — | Build orchestration via `Makefile` — targets like `make build`, `make test`, `make lint`. |
| **GoReleaser** | `.goreleaser.yml` | Automated cross-platform release pipeline — builds binaries for Linux/macOS/Windows/ARM, publishes npm package and Homebrew formula. |

---

## 💾 Data & Storage Layer

| Technology | Library / Tool | Role |
|---|---|---|
| **Git + Git Worktrees** | `os/exec` wrapping `git` | The backbone of persistence. Each agent's **Hook** is a git worktree — a live checkout of the repo on a separate branch. Agent state survives crashes because it is committed to git. |
| **Dolt** | `dolthub/dolt` + `go-sql-driver/mysql v1.9.3` | A MySQL-compatible, git-versioned SQL database. Powers the **Wasteland** federated network — sharing work boards across remote Gas Towns via DoltHub. Runs as a server process (`internal/doltserver`), queried through the MySQL driver. |
| **SQLite3** | `mattn/go-sqlite3` (system) | Local database for convoy queries. Lightweight, requires no server. |
| **Beads (`bd`)** | `steveyegge/beads v0.63.3` | A git-backed issue tracker. Stores all work items as flat structured files in `.beads/` directly in the repo — the task management layer. Key commands: `bd create`, `bd ready`, `bd close`, `bd sync`. |
| **TOML** | `BurntSushi/toml v1.6.0` | Formula definitions — workflow templates stored as `.formula.toml` files in `internal/formula/formulas/`. |
| **YAML** | `gopkg.in/yaml.v3 v3.0.1` | Configuration files, settings, plugin manifests. |
| **Viper** | `spf13/viper v1.21.0` | Runtime config management — reads from env vars, config files, and CLI flags with layered priority. |
| **UUID** | `google/uuid v1.6.0` | Unique ID generation for convoys, events and sessions. |

---

## 🤖 Agent Runtime Integration

Gas Town is **runtime-agnostic** — it manages AI agents via tmux sessions and lifecycle hooks. Supported runtimes:

| Agent Runtime | Preset Name | Hook Mechanism |
|---|---|---|
| **Claude Code CLI** | `claude` | `.claude/settings.json` — hooks for `sessionStart`, `userPromptSubmitted`, `preToolUse`, `sessionEnd` |
| **GitHub Copilot CLI** | `copilot` | `.github/hooks/gastown.json` — same lifecycle events, uses `--yolo` autonomous mode |
| **Codex CLI** | `codex` | No native hooks; `gt prime` + `gt mail check --inject` sent as startup fallback |
| **Gemini** | `gemini` | Startup fallback pattern |
| **Cursor** | `cursor` | Startup fallback pattern |
| **Amp** | `amp` | Startup fallback pattern |
| **OpenCode** | `opencode` | Startup fallback pattern |
| **Pi** | `pi` | Startup fallback pattern |
| **OMP** | `omp` | Startup fallback pattern |

> Config is stored per-rig in `settings/config.json`. Custom agent commands can be added via `gt config agent set <alias> "<command>"`.

---

## 📦 Internal Package Map

The `internal/` directory contains 67 packages. Here are the most important:

| Package | Responsibility |
|---|---|
| `agent` | Agent lifecycle management — spawn, attach, detach, query agents by rig/role |
| `mayor` | Mayor role logic — the primary AI coordinator session |
| `polecat` | Worker agent lifecycle — spawn, track, and clean up polecat sessions |
| `witness` | Per-rig health monitor — detects stuck/zombie agents, triggers recovery |
| `deacon` | Cross-rig supervisor — continuous patrol, dispatches Dogs for maintenance |
| `refinery` | Per-rig merge queue — Bors-style bisecting merge processor |
| `scheduler` | Capacity governor — rate-limits polecat dispatch to avoid API exhaustion |
| `convoy` | Work-tracking units that bundle multiple beads and track assignment/completion |
| `hooks` | Git worktree management — creation, activation, archival, repair |
| `hookutil` | Utilities for hook state reading/writing |
| `beads` | Go wrapper around the `bd` CLI for programmatic issue manipulation |
| `formula` | TOML formula loading/instantiation — workflow templates (Molecules) |
| `session` | Session discovery and `.events.jsonl` log management (used by Seance) |
| `mail` | Agent mailbox — persistent messages delivered at session startup |
| `nudge` | Immediate in-session message delivery to live tmux sessions |
| `tmux` | Go wrapper for `tmux` — create/attach/send-keys/query sessions |
| `feed` | `gt feed` TUI logic — Bubbletea model for the activity dashboard |
| `tui` / `ui` | Shared TUI/UI components and styling utilities |
| `web` | `gt dashboard` HTTP server — htmx-driven browser UI |
| `templates` | Go `html/template` files for the web dashboard |
| `telemetry` | OpenTelemetry initialization, meter/logger providers, metric definitions |
| `daemon` | Background daemon process — heartbeat, scheduler dispatch, patrol cycles |
| `reaper` | Zombie process cleanup — detects and cleans dead tmux sessions |
| `estop` | Emergency stop — halts all agent activity safely |
| `config` | Viper-based config loading and writing |
| `runtime` | Agent runtime configuration and detection logic |
| `git` | Low-level git command wrappers (clone, worktree, commit, push) |
| `github` | GitHub API interactions (PR creation, labels) |
| `wasteland` | Dolt-backed federated work coordination (wanted board, claims, stamps) |
| `doltserver` | Manages the Dolt server subprocess lifecycle |
| `protocol` | Inter-agent communication protocol primitives |
| `mq` | Message queue — async event delivery between components |
| `channelevents` | Structured event types for the activity channel |
| `activity` | Activity log reader/writer (`.events.jsonl` format) |
| `agentlog` | Agent output log management |
| `townlog` | Town-level event logging |
| `health` | Agent health state definitions (Working, Stalled, Zombie, etc.) |
| `doctor` | Health diagnostics and auto-repair routines |
| `checkpoint` | Molecule step checkpointing (for recoverable workflow execution) |
| `quota` | API quota tracking per agent runtime |
| `lock` | File locking wrappers around `gofrs/flock` |
| `krc` | Keep-running-context — agent session continuation primitives |
| `keepalive` | Session keepalive pings to prevent idle disconnects |
| `acp` | Agent Control Protocol — structured command passing to agent sessions |
| `proxy` | `gt-proxy` — transparent proxy for MCP/tool call interception |
| `connection` | Network connection utilities |
| `boot` | Boot sequence for workspace initialization |
| `rig` | Rig management — add, remove, list project containers |
| `crew` | Crew workspace management |
| `workspace` | Top-level workspace (town) utilities |
| `shell` | Shell execution helpers — run commands, capture output |
| `suggest` | Agent suggestion system — hints delivered on session startup |
| `wisp` | Molecule sub-step units (Poured Wisps = checkpointable steps) |
| `dog` | Dogs — infrastructure maintenance workers dispatched by the Deacon |
| `plugin` | Plugin system loader — extends `gt` with external capabilities |
| `wrappers` | External tool wrappers (ripgrep, gh CLI, etc.) |
| `deps` | Dependency checker — validates env prerequisites at startup |
| `version` | Version info embedding |
| `constants` | Shared constant definitions |
| `testutil` | Testing helpers and fixtures |

---

## 🖥️ Terminal UI (TUI)

| Technology | Library | Role |
|---|---|---|
| **Bubbletea** | `charmbracelet/bubbletea v1.3.10` | Elm-architecture TUI framework powering `gt feed` — the interactive live monitoring dashboard. Uses a Model-Update-View pattern driven by messages. |
| **Bubbles** | `charmbracelet/bubbles v1.0.0` | Ready-made TUI components — text inputs, spinners, lists, viewports — used within Bubbletea models. |
| **Lipgloss** | `charmbracelet/lipgloss v1.1.1` | Terminal styling — borders, colors, padding, alignment, and layout for all TUI output. |
| **Glamour** | `charmbracelet/glamour v0.10.0` | Renders Markdown beautifully inside the terminal (agent output, role documentation). |
| **Termenv** | `muesli/termenv v0.16.0` | Terminal capability detection — ANSI/256/true-color adaptation. |
| **Chroma** | `alecthomas/chroma/v2` | Syntax highlighting for code shown in the TUI (via Glamour). |

### `gt feed` Dashboard Panels

- **Agent Tree** — Hierarchical view of all agents grouped by rig and role
- **Convoy Panel** — In-progress and recently-landed convoys with status
- **Event Stream** — Chronological feed of creates, completions, slings, nudges, escalations
- **Problems View** (`p` key or `--problems`) — Surfaces stuck/zombie agents needing intervention

---

## 🌐 Web Dashboard

| Technology | Library | Role |
|---|---|---|
| **Go `net/http`** | Standard library | Built-in HTTP server powers `gt dashboard`. No external web framework. |
| **htmx** | CDN-loaded JS | Makes the dashboard auto-refresh. HTML elements make async HTTP requests enabling live-updating UI without a SPA framework. |
| **Go `html/template`** | Standard library | Server-side HTML rendering for all dashboard pages (`internal/templates/`). |
| **otelhttp** | `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.61.0` | Auto-instruments the HTTP server with OTEL traces per request. |

> **Access:** `gt dashboard` (default port 8080). Exposes agents, convoys, hooks, queues, issues, and escalations. Includes a command palette for running `gt` commands directly from the browser.

---

## 🔒 Concurrency & Process Management

| Technology | Library | Role |
|---|---|---|
| **File Locking** | `gofrs/flock v0.13.0` | Prevents race conditions when multiple agents/processes write to shared git state simultaneously. |
| **Rate Limiting** | `golang.org/x/time v0.15.0` | Token-bucket rate limiter in the scheduler — controls concurrent polecat dispatch to avoid API quota exhaustion. |
| **Init System** | `tini` (system package) | Lightweight PID 1 init inside Docker to properly reap zombie child processes. |
| **File Watching** | `fsnotify v1.9.0` | Filesystem event notifications — detects changes to hooks/beads/config files without polling. |
| **Log Rotation** | `lumberjack.v2 v2.2.1` | Automatic log file rotation for long-running daemon processes. |
| **gopsutil** | `shirou/gopsutil/v4 v4.26.2` | Process and system metrics collection (CPU, memory) for agent health diagnostics. |

---

## 📡 Observability (Telemetry)

Gas Town uses **OpenTelemetry** to emit structured logs, metrics, and traces for every agent operation.

| Technology | Library | Role |
|---|---|---|
| **OTEL SDK** | `go.opentelemetry.io/otel v1.42.0` | Core OTEL API + SDK — spans, meters, loggers. |
| **OTLP Log Exporter** | `otlploghttp v0.18.0` | Ships structured logs over HTTP to VictoriaLogs (or any OTLP backend). |
| **OTLP Metric Exporter** | `otlpmetrichttp v1.42.0` | Ships metrics over HTTP to VictoriaMetrics (or any OTLP backend). |
| **gRPC + Protobuf** | `google.golang.org/grpc v1.79.3` | Used internally by the OTLP exporter chain for efficient, structured telemetry transport. |

### Key Metrics

| Metric | Description |
|---|---|
| `gastown.session.starts.total` | Total agent sessions started |
| `gastown.bd.calls.total` | Total `bd` CLI invocations |
| `gastown.polecat.spawns.total` | Total worker agents spawned |
| `gastown.done.total` | Total work completions |
| `gastown.convoy.creates.total` | Total convoys created |

> **Config:** Set `GT_OTEL_LOGS_URL` and `GT_OTEL_METRICS_URL` environment variables to enable telemetry export.

---

## 🐳 Infrastructure & Packaging

| Technology | File | Role |
|---|---|---|
| **Docker** | `Dockerfile` | Builds from `docker/sandbox-templates:claude-code` (Anthropic's Claude sandbox image). Installs Go, tmux, sqlite3, ripgrep, Dolt, Beads, Node.js, and the `gt` binary. |
| **Docker Compose** | `docker-compose.yml` | Wires up volumes (agent home, dolt data), ports (8080), and env vars. Mounts host `$FOLDER` into `/gt`. Security-hardened: drops all Linux capabilities, re-grants only required ones. |
| **Nix Flakes** | `flake.nix` / `flake.lock` | Hermetic, reproducible dev environment. Enables `nix develop` as an alternative to Homebrew/npm installs. |
| **GoReleaser** | `.goreleaser.yml` | Cross-platform release: Linux/macOS/Windows/ARM binaries, npm package, Homebrew formula, GitHub releases. |
| **npm package** | `npm-package/` | Wraps the binary for distribution via `npm install -g @gastown/gt`. |
| **GitHub Actions** | `.github/` | CI/CD: testing, linting (`golangci-lint`), and release automation. |
| **Renovate** | `renovate.json` | Automated dependency update bot — keeps Go modules, npm deps up-to-date. |

### Dockerfile Deep Dive

```
Base: docker/sandbox-templates:claude-code
  ↓ apt install: git, tmux, sqlite3, ripgrep, zsh, gh, tini, vim
  ↓ Go 1.25.8 from official tarball (apt version too old)
  ↓ Beads (bd) installed via install script
  ↓ Dolt installed via install script
  ↓ Node.js LTS (v22) via nodesource
  ↓ make build → produces gt binary at /app/gastown/gt
  ↓ ENTRYPOINT: tini → docker-entrypoint.sh
```

---

## 🌍 Federated Networking (Wasteland)

| Technology | Role |
|---|---|
| **DoltHub** | Cloud hosting for Dolt databases. The Wasteland uses it as a decentralized bulletin board — multiple Gas Towns post wanted items, claim work, submit evidence, and earn reputation **stamps** across the internet. |
| **MySQL driver** (`go-sql-driver/mysql v1.9.3`) | Dolt exposes a MySQL-compatible interface; this driver is used to query it from Go. |
| **Reputation Stamps** | Multi-dimensional scoring: quality, speed, complexity. Earned on completion and attached to the agent's portable identity. |

### Wasteland Workflow

```
gt wl join <remote>          → Connect to a federated Gas Town
gt wl browse                 → Browse the wanted board (Dolt DB)
gt wl claim <id>             → Claim a work item
gt wl done <id> --evidence   → Submit completion + earn stamps
gt wl post --title "Need X"  → Post a new wanted item
```

---

## 🧪 Testing Stack

| Technology | Library | Role |
|---|---|---|
| **Testify** | `stretchr/testify v1.11.1` | Go assertions (`assert`, `require`) and test suite organization. |
| **Testcontainers** | `testcontainers-go v0.41.0` | Spins up real Docker containers (including Dolt via the `dolt` module) for integration tests — no mocking required for DB-level tests. |
| **go-rod** | `go-rod/rod v0.116.2` | Headless Chromium browser automation for E2E tests (uses `Dockerfile.e2e` with a headless browser). |
| **golangci-lint** | `.golangci.yml` | Static analysis — runs dozens of linters (errcheck, staticcheck, govet, etc.) to enforce code quality. |
| **Codecov** | `codecov.yml` | Code coverage tracking and PR reporting on CI. |

---

## 🎭 Key Concepts & Roles

| Role | Description | Started With |
|---|---|---|
| **Mayor** 🎩 | Primary AI coordinator. Breaks down goals, creates convoys, spawns polecats. | `gt mayor attach` |
| **Polecat** 🦨 | Worker agent with persistent identity but ephemeral sessions. Spawned per task. | `gt sling <bead-id> <rig>` |
| **Witness** 👁️ | Per-rig health monitor. Detects stuck/zombie agents, triggers recovery or handoff. | Automatic per rig |
| **Deacon** 🛡️ | Cross-rig background supervisor. Dispatches Dogs for maintenance, escalates issues. | `gt patrol` |
| **Refinery** 🏭 | Per-rig Bors-style merge queue. Batches and bisects polecat branch merges. | Automatic |
| **Dogs** 🐕 | Infrastructure workers dispatched by the Deacon (e.g., Boot for triage). | Dispatched by Deacon |
| **Hook** 🪝 | Git worktree-based persistent storage for one agent's work state. | Created by `gt sling` |
| **Convoy** 🚚 | Work-tracking unit bundling multiple beads assigned to agents. | `gt convoy create` |
| **Molecule** 🧬 | An instantiated workflow formula with tracked step execution. | `bd mol pour <formula>` |
| **Seance** 👻 | Session discovery — agents query predecessor sessions for context recovery. | `gt seance` |

### Three-Tier Watchdog System

```
Daemon (Go process) ← heartbeat every 3 min
    └── Boot (AI agent) ← initial intelligent triage
        └── Deacon (AI agent) ← continuous patrol across all rigs
            └── Witness (per-rig) ← detects and recovers stuck polecats
                └── Refinery (per-rig) ← merge queue processor
```

### Escalation Routing

```
Agent hits blocker
    └── gt escalate -s HIGH "description"
        └── Deacon picks up escalation bead
            └── Routes to Mayor (P1/P2)
                └── Routes to Overseer / Human (P0 CRITICAL)
```

---

## 🔄 Data Flow & Lifecycle

### Work Item Lifecycle

```
bd create --title "Task"     → Bead created in .beads/
gt convoy create "Sprint" <bead-id>  → Convoy wraps the bead
gt sling <bead-id> <rig>     → Hook created (git worktree), polecat spawned
  └── Agent runs in tmux session
  └── Agent state committed to hook branch
gt done                      → Branch pushed, MR bead created
  └── Refinery batches MR
  └── Verification gates run
  └── Merges to main (or bisects on failure)
bd close <id>                → Bead marked complete, convoy updated
```

### Hook Lifecycle

```
Created  → Active (work assigned)
Active   → Suspended (agent paused)
Suspended→ Active (agent resumed)
Active   → Completed (work done)
Completed→ Archived
```

### Session Communication

| Method | Mechanism | Use Case |
|---|---|---|
| **Mail** | Persistent files read on session start | Detailed task handoffs, instructions |
| **Nudge** | `tmux send-keys` to live session | Wake sleeping agent, short alerts |
| **Hooks** | Git-committed state files | Work context, progress across restarts |
| **Events** | `.events.jsonl` append-only logs | Seance context recovery, activity feed |

---

## 💡 Design Philosophy

> **Git is the source of truth.**

Every piece of agent state, every work item, and every coordination message flows through git. This makes the entire system:

| Property | How Achieved |
|---|---|
| ✅ **Crash-safe** | Agents resume exactly where they left off via git-committed hook state |
| ✅ **Auditable** | Full history of every agent decision in git log |
| ✅ **Rollback-able** | Revert any agent's work to a previous commit |
| ✅ **Scalable** | Proven to coordinate 20–30 concurrent AI agents |
| ✅ **Runtime-agnostic** | Any AI CLI tool can be plugged in as an agent |
| ✅ **Observable** | Every operation emits OTEL metrics, logs, and traces |

### The Propulsion Principle

Each agent's **Hook** (git worktree) acts as a propulsion mechanism:
1. Work is assigned → hook branch created
2. Agent commits progress continuously → state persists through crashes
3. Work completes → branch goes through Refinery merge queue
4. Main branch advances → other agents see the change

---

*Generated from codebase analysis of `github.com/steveyegge/gastown` — Go 1.25.8, 67 internal packages, 135 dependencies.*
