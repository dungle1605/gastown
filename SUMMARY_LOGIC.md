🏙️ Gas Town — Technology Overview
Gas Town is a multi-agent AI orchestration system written primarily in Go. Here's every key technology layer and what each one does:

🔧 Core Language & Build
Technology	Role
Go 1.25+	Primary language. All of the gt CLI and internal packages are written in Go. Chosen for its performance, single-binary output, and strong concurrency model.
Cobra (spf13/cobra)	CLI framework that powers all gt sub-commands (gt sling, gt convoy, gt mayor, etc.).
Make	Build orchestration via Makefile — targets like make build, make test.
💾 Data & Storage
Technology	Role
Git + Git Worktrees	The backbone of persistence. Each agent's "hook" is a git worktree — a live checkout of the same repo on a separate branch. Agent state survives crashes because it's committed to git.
Dolt (dolthub/dolt)	A MySQL-compatible, git-versioned SQL database. Used for the Wasteland federated network — sharing work boards across remote Gas Towns via DoltHub. Think git but for relational data.
SQLite3	Used locally for convoy database queries. Lightweight and requires no server process.
Beads (bd)	A git-backed issue tracker (flat files + git). Stores all work items (beads/issues) as structured data directly in the repo. Acts as the project's task management layer.
TOML (BurntSushi/toml)	Formula definitions (workflow templates stored as .formula.toml files).
YAML (gopkg.in/yaml.v3)	Configuration files and settings.
Viper (spf13/viper)	Runtime config management — reads from env vars, config files, and command-line flags.
🖥️ Terminal UI (TUI)
Technology	Role
Bubbletea (charmbracelet/bubbletea)	The Elm-architecture TUI framework powering gt feed — the interactive live monitoring dashboard in the terminal.
Bubbles (charmbracelet/bubbles)	Ready-made TUI components (text inputs, spinners, etc.) used within Bubbletea apps.
Lipgloss (charmbracelet/lipgloss)	Terminal styling — borders, colors, typography for the TUI.
Glamour (charmbracelet/glamour)	Renders Markdown beautifully inside the terminal (e.g., agent output, documentation).
Termenv / muesli	Terminal color detection and ANSI output helpers.
🌐 Web Dashboard
Technology	Role
Go net/http	Built-in HTTP server powers gt dashboard. No external web framework needed.
htmx	The dashboard auto-refreshes via htmx — a lightweight JS library that lets HTML elements make async HTTP requests, enabling a live-updating UI without a SPA framework.
HTML templates (internal/templates)	Go's html/template package renders the dashboard pages server-side.
📡 Observability (Telemetry)
Technology	Role
OpenTelemetry (OTEL) (go.opentelemetry.io/otel)	Industry-standard observability framework. Gas Town emits logs, metrics, and traces for every agent operation.
OTLP HTTP exporters	Ships telemetry data over HTTP to any OTLP-compatible backend (default: VictoriaMetrics/VictoriaLogs).
Metrics collected	gastown.session.starts.total, gastown.bd.calls.total, gastown.polecat.spawns.total, etc.
🤖 Agent Runtime Integration
Technology	Role
Claude Code CLI	Default AI agent runtime. Gas Town manages Claude sessions via tmux and lifecycle hooks in .claude/settings.json.
tmux	Terminal multiplexer used to manage multiple simultaneous AI agent sessions. Each polecat/mayor/witness lives in a tmux session.
GitHub Copilot CLI	Optional agent runtime using --yolo autonomous mode + .github/hooks/gastown.json lifecycle hooks.
Codex CLI	OpenAI Codex as an optional agent runtime.
Gemini, Cursor, Amp, OpenCode	Additional built-in agent presets — Gas Town is runtime-agnostic.
🔒 Concurrency & Process Management
Technology	Role
gofrs/flock	File locking — prevents race conditions when multiple agents/processes write to shared state simultaneously.
golang.org/x/time	Rate limiting for the scheduler — controls how many polecats can be dispatched concurrently to avoid API quota exhaustion.
tini	Lightweight init system used in Docker to properly reap zombie processes inside containers.
fsnotify	File system watching — detects changes to hook/bead/config files without polling.
lumberjack	Log rotation for long-running daemon processes.
🐳 Infrastructure / Packaging
Technology	Role
Docker + Docker Compose	Containerized environment. Dockerfile builds from docker/sandbox-templates:claude-code (Anthropic's Claude sandbox). docker-compose.yml wires up volumes, ports, and environment.
Nix Flakes (flake.nix)	Hermetic, reproducible dev environment and packaging. Alternative to Homebrew/npm installs — enables nix develop for contributors.
GoReleaser (.goreleaser.yml)	Automated cross-platform release pipeline — builds binaries for Linux/macOS/Windows/ARM, publishes npm package, Homebrew formula, and GitHub releases.
npm package (npm-package/)	Wraps the binary for distribution via npm install -g @gastown/gt.
🧪 Testing
Technology	Role
Testify (stretchr/testify)	Go assertions and test suite helpers.
Testcontainers	Spins up real Docker containers (including Dolt) for integration tests — no mocking needed for DB tests.
go-rod	Headless browser automation for E2E tests (uses Dockerfile.e2e).
Codecov (codecov.yml)	Code coverage tracking and reporting on CI.
🌍 Federated Networking
Technology	Role
DoltHub	Cloud hosting for Dolt databases. The Wasteland uses it as a decentralized bulletin board — multiple Gas Towns can share work items and reputation stamps across the internet.
MySQL driver (go-sql-driver/mysql)	Dolt exposes a MySQL-compatible interface, so this driver is used to query it.
gRPC + Protobuf	Used internally for OTLP telemetry export (the OTEL exporter chain uses gRPC under the hood).
Summary Architecture Map
User / Human
    │
    └── gt CLI (Go + Cobra)
            │
            ├── tmux sessions ─── AI Agents (Claude, Codex, Copilot, etc.)
            │        │                   │
            │        └── Hooks      Git worktrees (persistent state)
            │
            ├── Beads (bd) ──── Git-backed issue tracking
            ├── Dolt ─────────── SQL + versioned DB (Wasteland federation)
            ├── SQLite ────────── Local convoy queries
            │
            ├── TUI (Bubbletea) ── gt feed dashboard
            ├── Web (htmx) ─────── gt dashboard (browser)
            └── OTEL ───────────── Telemetry → VictoriaMetrics/Logs
The system's core philosophy is git as the source of truth — agent state, work items, and coordination all flow through git, making everything auditable, rollback-able, and crash-safe.

