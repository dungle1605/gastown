# Gas Town — Getting Started Guide

> Based on your current configuration:
> - **User:** Michael `<dugle1605@gmail.com>`
> - **Workspace:** `/home/michael/gt` (host) → `/gt` (inside container)
> - **Project Rig:** `gymastic` (from `https://github.com/dungle1605/Gymastic.git`)
> - **Dashboard:** `http://localhost:8080`
> - **Container:** `gastown-sandbox` ✅ Running

---

## Step 1 — Enter the Container

Open a terminal and run:

```bash
# From your gastown repo directory
cd /home/michael/github-repo/gastown

docker compose exec gastown zsh
```

You are now inside the container. Your working directory is `/gt` — the Gas Town workspace.

---

## Step 2 — Verify Everything is Ready

```bash
cd /gt

# Check gt CLI
gt --version

# Check beads (issue tracker)
bd --version

# Check your rig
gt rig list
```

Expected output:
```
🟡 gymastic
   Witness: ● running  Refinery: ○ stopped
   Polecats: 0  Crew: 0
```

---

## Step 3 — Create Your Crew Workspace

A **crew** is your personal working directory inside the `gymastic` rig.

```bash
cd /gt
gt crew add michael --rig gymastic
```

This creates:
```
/gt/gymastic/crew/michael/   ← your personal workspace
```

Now enter it:
```bash
cd /gt/gymastic/crew/michael
```

This is where you do hands-on coding work on the Gymastic project.

---

## Step 4 — Start the Mayor (Your AI Coordinator)

The **Mayor** is the primary Claude AI agent that orchestrates all work.

```bash
# From anywhere inside the container
gt mayor attach
```

This opens a **tmux window** with a Claude session running as the Mayor.
Inside the Mayor session, you can just talk to it in plain English:

```
"I want to add a dark mode to the Gymastic app"
"Create a login page for the Gymastic project"
"Fix all the TypeScript errors in the project"
```

The Mayor will:
1. Break your request into tasks (Beads)
2. Create a Convoy to track them
3. Spawn Polecat worker agents
4. Report progress back to you

**Detach from Mayor without stopping it:** press `Ctrl+B` then `D`

---

## Step 5 — Monitor Agent Activity

### Option A: Terminal TUI Dashboard

```bash
gt feed
```

Shows a live 3-panel view:
- Agent tree (all active agents)
- Convoy status (work in progress)
- Event stream (real-time activity)

Navigate with `j`/`k`, switch panels with `Tab`, quit with `q`.

### Option B: Web Dashboard

```bash
gt dashboard
```

Then open **http://localhost:8080** in your browser.
Shows agents, convoys, hooks, and queues with auto-refresh.

---

## Step 6 — Create Work Items (Beads)

You can manually create work items if you don't want the Mayor to do it:

```bash
cd /gt

# Create a task bead
bd create --title "Add dark mode to Gymastic" --type=task --priority=2

# See all open tasks
bd list --status=open

# See what's ready to work on (unblocked tasks)
bd ready
```

---

## Step 7 — Assign Work to an Agent (Sling)

Once you have bead IDs, assign them to the Gymastic rig:

```bash
# Replace gy-abc12 with your actual bead ID from `bd list`
gt sling gy-abc12 gymastic
```

This:
1. Creates a **Hook** (git worktree) for the agent to work in
2. Spawns a **Polecat** (Claude) in a new tmux session
3. Injects the task description via mail

---

## Step 8 — Track Progress

```bash
# List all convoys (work packages)
gt convoy list

# Show details of a specific convoy
gt convoy show

# See all active agents
gt agents

# Watch the live feed
gt feed
```

---

## Quick Reference — Your Workspace Layout

```
/gt/                          ← Gas Town HQ (your workspace)
├── CLAUDE.md                 ← Mayor's identity/instructions
├── mayor/                    ← Mayor agent home
├── deacon/                   ← Background supervisor
├── gymastic/                 ← Your Gymastic project rig
│   ├── crew/michael/         ← YOUR personal workspace ← work here
│   ├── polecats/             ← Worker agents (spawned per task)
│   ├── witness/              ← Per-rig health monitor
│   ├── refinery/             ← Merge queue processor
│   └── mayor/rig/            ← Mayor's clone of Gymastic repo
└── plugins/                  ← Gas Town plugins
```

---

## Common Commands Cheatsheet

| Goal | Command |
|------|---------|
| Enter container | `docker compose exec gastown zsh` |
| Start Mayor AI | `gt mayor attach` |
| Live terminal dashboard | `gt feed` |
| Web dashboard | `gt dashboard` (→ http://localhost:8080) |
| Create task | `bd create --title "..." --type=task` |
| List open tasks | `bd list --status=open` |
| Assign task to agent | `gt sling <bead-id> gymastic` |
| See all agents | `gt agents` |
| See convoy status | `gt convoy list` |
| Health check | `gt doctor` |
| Fix issues | `gt doctor --fix` |
| Restart container | `docker compose restart` |
| Stop everything | `docker compose down` |

---

## Workflow: Mayor-Driven (Recommended for Beginners)

This is the simplest way to use Gas Town:

```
1. docker compose exec gastown zsh    ← enter container
2. gt mayor attach                    ← open Mayor session
3. Tell Mayor: "Add feature X"        ← plain English
4. Ctrl+B, D                          ← detach from Mayor tmux
5. gt feed                            ← watch agents work
6. gt convoy list                     ← check progress
```

The Mayor handles everything else automatically.

---

## Troubleshooting

### bd command not found or broken
```bash
# ICU library fix (already applied in running container)
# If it breaks again after rebuild:
docker compose exec -u root gastown bash -c "
  ICU_VER=\$(ls /usr/lib/x86_64-linux-gnu/libicui18n.so.*.* | grep -oP '(?<=\.so\.)\d+' | sort -n | tail -1)
  ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.\${ICU_VER} /usr/lib/x86_64-linux-gnu/libicui18n.so.74
  ln -sf /usr/lib/x86_64-linux-gnu/libicuuc.so.\${ICU_VER}   /usr/lib/x86_64-linux-gnu/libicuuc.so.74
  ln -sf /usr/lib/x86_64-linux-gnu/libicudata.so.\${ICU_VER} /usr/lib/x86_64-linux-gnu/libicudata.so.74
"
```

### Doctor warnings
```bash
cd /gt && gt doctor --fix
```

### Mayor not responding
```bash
gt mayor detach
gt mayor attach
```

### Container stopped
```bash
cd /home/michael/github-repo/gastown
docker compose up -d
```
