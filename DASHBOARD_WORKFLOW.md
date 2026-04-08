# Gas Town Dashboard Workflow & Architecture

This document provides a conceptual overview of the system architecture as seen from the `gt dashboard` (Web UI at `http://localhost:8080` or Terminal TUI via `gt feed`).

## The Cast of Characters (Roles)

Gas Town uses a multi-agent system where different AI personas specialize in different parts of the software development lifecycle:

1. **🧑‍💻 Crew (Human)**
   - This is you! You use your personal workspace inside the Rig to give instructions, intervene if the AI gets stuck, or just write your own code.

2. **🎩 The Mayor (Coordinator Level)**
   - The lead AI orchestrator. It doesn't write your code directly. Its job is to take your plain-English requests, break them down into bite-sized tasks, and assign them out to workers.

3. **🦡 Polecats (Worker Level)**
   - Ephemeral AI coding agents (usually Claude). The Mayor spins these up dynamically. A Polecat is given a single task, a fresh branch, and its only job is to write the code to finish that task.

4. **👁️ Witness (QA Level)**
   - The health monitor/tester. This AI patrols the repository independently to find bugs, type errors, or broken tests and reports them back to the Mayor as new issues.

5. **🏭 Refinery (Release Level)**
   - The gatekeeper. When a Polecat finishes a task, it doesn't immediately get added to `main`. It goes to the Refinery, which reviews the code, resolves conflicts, and merges it safely.

6. **⛪ Deacon (System Level)**
   - The background supervisor. It monitors the health of the Gas Town container, cleans up orphaned processes, handles system logging, and wakes sleeping agents.

7. **🐕 Dogs (Janitorial Level)**
   - Simple, non-AI scripts executing background maintenance (like database compaction, wisp deletion, and log rotation).

---

## The Dashboard Event Workflow

When you attach to the Mayor (`gt mayor attach`) and type a request (e.g., *"Add a dark mode toggle"*), here is how the event plays out step-by-step across the dashboard panels:

### 1. The Request Phase
- **Mail Panel (Left):** Your request is conceptually sent as "mail" or a "nudge" to the Mayor.
- **Work Panel (Bottom Left):** The Mayor breaks your request down into multiple tracked "Beads" (essentially GitHub issues or Jira tickets) and assigns priorities (P0, P1, P2) to each.

### 2. The Planning Phase
- **Convoys Panel (Top Left):** The Mayor bundles related "Work" tasks into a **Convoy**. A convoy is a single project-level tracker that waits for all member sub-tasks to complete.

### 3. The Execution Phase
- **Hooks Panel (Bottom):** The Mayor creates a Git Worktree (a "Hook") so that work can be done in isolation without breaking your main branch.
- **Polecats Panel (Middle):** You watch as the Mayor spins up a new `Polecat` agent, assigning it to the newly created Hook. The Polecat will begin aggressively reading files and writing code in the background.

### 4. The Review Phase
- **Merge Queue Panel (Bottom Middle):** Once a Polecat is done, its work is submitted as a PR branch. It appears in the Merge Queue waiting for the **Refinery** to review, accept, and merge it into the main codebase.

### 5. Real-Time Tracking
- **Sessions & Activity Panels (Right):** Throughout this entire process, you can watch the exact commands, commits, and hand-offs occurring in the Activity feed. Every time an agent spins up or sends a message between sessions, it is logged here.
- **Escalations Panel:** If a Polecat fails its task repeatedly, or the Witness finds a critical bug, it will ping an Escalation here for **you** (the Human Crew member) to intervene, provide guidance, or rescue them.
