[ARCHITECTURE.md](https://github.com/user-attachments/files/27546951/ARCHITECTURE.md)
# A3RO Architecture

This document describes the bounded contexts, agent model, topology options, event sourcing strategy, and end-to-end data flow of the A3RO platform.

---

## Bounded Contexts

A3RO is organised as eleven primary bounded contexts, each mapped to one or more packages. Two cross-cutting packages (`@a3ro/telemetry`, `@a3ro/security`) serve all contexts.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         A3RO Platform                               │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐   │
│  │   Domain     │   │ Presentation │   │    Configuration     │   │
│  │ @a3ro/types  │   │ @a3ro/cli    │   │   @a3ro/config       │   │
│  │              │   │ @a3ro/fmtr   │   │                      │   │
│  └──────┬───────┘   └──────┬───────┘   └──────────────────────┘   │
│         │                  │                                        │
│  ┌──────▼───────┐   ┌──────▼───────┐   ┌──────────────────────┐   │
│  │ Orchestration│◄──│    Swarm     │   │       Memory         │   │
│  │ @a3ro/orch.. │   │ @a3ro/swarm  │   │   @a3ro/memory       │   │
│  └──────┬───────┘   └──────┬───────┘   └──────────────────────┘   │
│         │                  │                                        │
│  ┌──────▼───────┐   ┌──────▼───────┐   ┌──────────────────────┐   │
│  │    Events    │   │    Agent     │   │       Tools          │   │
│  │ @a3ro/events │   │ @a3ro/agent  │   │   @a3ro/tools        │   │
│  └──────────────┘   └──────┬───────┘   └──────────────────────┘   │
│                             │                                        │
│  ┌──────────────┐   ┌──────▼───────┐                               │
│  │   Plugins    │   │  Transport   │                               │
│  │@a3ro/plugins │   │@a3ro/transp. │                               │
│  └──────────────┘   └──────────────┘                               │
│                                                                     │
│  ─ ─ ─ ─ ─ ─ ─  Cross-cutting  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│  ┌──────────────┐   ┌──────────────────────────────────────────┐   │
│  │  Telemetry   │   │               Security                   │   │
│  │@a3ro/telemetry│  │            @a3ro/security                │   │
│  └──────────────┘   └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 1. Domain (`@a3ro/types`)

The single source of truth for all domain types. Every other package imports from here; nothing imports from a domain consumer. Contains:

- **Zod schemas** — `AgentSchema`, `SwarmSchema`, `TaskSchema`, `MemoryEntrySchema`, `EventSchema`, `ConfigSchema` and their `Create*Input` variants
- **Enums** — `AgentRole`, `AgentStatus`, `SwarmTopology`, `SwarmStatus`, `TaskStatus`, `EventType`, `LogLevel`, `OutputFormat`, `TransportType`, `MemoryBackend`
- **Service interfaces** — `IMemoryService`, `IEventStore`, `IAgent`, `ISwarmCoordinator`, `IFormatter`, `ITool`, `ITransportChannel`
- **Helpers** — `safeParse<T>()`, `formatZodError()`

### 2. Configuration (`@a3ro/config`)

Assembles runtime configuration from three layers (defaults → file → env). Provides:

- `loadConfig(cwd?)` — main entry; searches `.claude/settings.json`, `.a3ro/config.json`, `a3ro.config.json`
- `loadConfigFromFile(path)` — load an explicit path
- `parseEnv()` — maps `A3RO_*` / `ANTHROPIC_*` / `CLAUDE_FLOW_*` env vars to config keys
- `validateConfig(raw)` / `validatePartialConfig(raw)` — thin wrappers over `A3ROConfigSchema`

### 3. Presentation (`@a3ro/cli` + `@a3ro/formatter`)

`@a3ro/formatter` is a minimal `IFormatter` implementation used by packages that need lightweight output (no CLI dep). `@a3ro/cli` provides the full user-facing surface:

- `createCLI()` — builds the Commander program; registers commands lazily via `LazyCommandRegistry`
- `OutputFormatter` — level-aware (QUIET / NORMAL / VERBOSE / DEBUG), mode-aware (text / json), writes to `process.stdout` / `process.stderr`
- **Commands**: `agent`, `swarm`, `task`, `memory`, `config`, `status`, `version`, `daemon`, `help` — each with sub-commands

### 4. Memory (`@a3ro/memory`)

Two-layer memory system:

- **`InMemoryService`** — legacy `get/set/delete/list/clear` API keyed by optional `agentId` (used by `OrchestratorEngine`)
- **`MemoryService`** — new namespace-scoped `store/retrieve/search/clear` API backed by a `MemoryBackend`
- **`InMemoryBackend`** — substring-search backend (`Map<namespace, Map<key, value>>`); HNSW replaces substring scan in Session 3
- **`QueryBuilder`** — fluent API for building search parameters (`query`, `limit`, `tags`, `similarityThreshold`)
- **`createBackend(type)`** — factory with exhaustive switch; supports `'in-memory'` today

### 5. Swarm (`@a3ro/swarm`)

Swarm coordination and agent lifecycle within a swarm:

- **`SwarmCoordinator`** (`ISwarmCoordinator`) — CRUD for swarm entities; enforces capacity limits; transitions swarm status
- **`QueenCoordinator`** — spawns typed agents, dispatches tasks, tracks status transitions; maintains an internal `EventStore`
- **`EventStore`** — lightweight append-only log internal to a swarm; supports `replay(fromTimestamp?)` for point-in-time reconstruction

### 6. Agent (`@a3ro/agent`)

Abstract foundation for all agent implementations:

- **`BaseAgent`** (`IAgent`) — manages the `AgentStatus` state machine (idle → running → paused / stopped); exposes lifecycle hooks (`onStart`, `onStop`, `onPause`, `onResume`)
- **`abstract execute(task)`** — subclasses implement this to connect to the Anthropic SDK (Session 3)
- Config: model, maxTokens, temperature, tools, maxConcurrentTasks, timeoutMs

### 7. Orchestration (`@a3ro/orchestrator`)

High-level workflow coordinator that bridges swarms, memory, and events:

- **`OrchestratorEngine`** — `start/stop`, `dispatch(task, swarmId)`, `complete(taskId, output)`, `fail(taskId, error)`, `getActiveTasks(swarmId)`
- Writes task state to `IMemoryService` under `task:<id>` keys
- Emits `TaskAssigned`, `TaskCompleted`, `TaskFailed` events to `IEventStore`

### 8. Tools (`@a3ro/tools`)

Runtime tool registry for agent capabilities:

- **`ToolRegistry`** — register/unregister/retrieve `ITool` implementations by name
- Tools expose `name`, `description`, and `execute(input): Promise<unknown>`

### 9. Events (`@a3ro/events`)

Durable event store for cross-system audit and replay:

- **`InMemoryEventStore`** (`IEventStore`) — append, query by aggregate, query by type, version tracking per aggregate
- Schema-validated via `EventSchema` (Zod); every event carries `id`, `type`, `aggregateId`, `aggregateType`, `payload`, `version`, `timestamp`

### 10. Transport (`@a3ro/transport`)

Inter-agent messaging layer, abstracted behind `ITransportChannel`:

- **`InProcessChannel`** — synchronous pub/sub within a single process; `send(to, msg)`, `subscribe(agentId, handler)`, `broadcast(msg)`, `close()`
- IPC, HTTP, and WebSocket transports are enumerated in `TransportType` and planned for Session 4

### 11. Plugins (`@a3ro/plugins`)

Dynamic extension mechanism:

- **`PluginRegistry`** — register and retrieve named `IPlugin` implementations at runtime
- Plugins are declared in config (`plugins: string[]`) and loaded on startup
- Enables third-party tools, custom memory backends, and transport adapters without modifying core packages

---

## 15 Agent Roles

Every agent in a swarm occupies exactly one `AgentRole`. The Queen Coordinator is the only privileged role; all others are peers.

| Role | Enum value | Responsibility |
|---|---|---|
| Queen Coordinator | `queen_coordinator` | Spawns agents, dispatches tasks, owns swarm event log |
| Security Architect | `security_architect` | Threat modelling, policy enforcement |
| Core Architect | `core_architect` | System design, API contracts |
| Code Reviewer | `code_reviewer` | Static analysis, PR review |
| Test Engineer | `test_engineer` | Test generation, coverage analysis |
| DevOps Engineer | `devops_engineer` | CI/CD, infrastructure, deployment |
| Data Analyst | `data_analyst` | Data pipelines, metrics, reporting |
| UX Designer | `ux_designer` | Interface design, usability |
| Product Manager | `product_manager` | Requirements, roadmap, prioritisation |
| Tech Writer | `tech_writer` | Documentation, runbooks |
| Research Analyst | `research_analyst` | Literature review, competitive analysis |
| Performance Engineer | `performance_engineer` | Profiling, optimisation, load testing |
| Integration Specialist | `integration_specialist` | Third-party APIs, adapter layers |
| ML Engineer | `ml_engineer` | Model selection, fine-tuning, evaluation |
| Debugger | `debugger` | Root cause analysis, patch generation |

---

## 5 Swarm Topologies

A swarm's topology defines how agents communicate and who can initiate work.

| Topology | Enum value | Description |
|---|---|---|
| Hierarchical | `hierarchical` | Queen at the top; all task assignment flows through the Queen Coordinator. Default. |
| Mesh | `mesh` | Every agent can communicate with every other agent peer-to-peer. High coordination cost, maximum parallelism. |
| Ring | `ring` | Agents pass work in a fixed circular order. Predictable latency, good for pipeline tasks. |
| Star | `star` | A single hub agent relays all messages. Simple routing, single point of failure. |
| Adaptive | `adaptive` | Topology reconfigured dynamically based on agent load and task dependency graph. |

---

## Event Sourcing Model

All significant state changes are captured as immutable `A3ROEvent` records. State is reconstructed by replaying events rather than querying a mutable row.

### Event schema

```
A3ROEvent {
  id             : UUID          — unique per event
  type           : EventType     — e.g. agent.created, task.completed
  aggregateId    : string        — the entity this event belongs to
  aggregateType  : enum          — agent | swarm | task | memory | system
  payload        : Record        — event-specific data
  metadata       : Record        — correlation IDs, source info
  timestamp      : ISO datetime
  version        : int ≥ 1       — monotonically increasing per aggregate
  correlationId? : UUID          — links events in the same logical operation
  causationId?   : UUID          — points to the event that caused this one
}
```

### Event types by domain

```
Agent lifecycle:    agent.created  agent.started  agent.stopped
                    agent.paused   agent.resumed  agent.failed

Swarm lifecycle:    swarm.created  swarm.started  swarm.stopped  swarm.scaled

Task lifecycle:     task.created   task.assigned  task.started
                    task.completed task.failed    task.cancelled  task.blocked

Memory:             memory.set     memory.deleted  memory.cleared

System:             system.started system.stopped  system.error
```

### Replay

```typescript
// Replay all events for an aggregate from version 3 onward
const events = await eventStore.getEvents(agentId, 3);

// Replay all events of a given type (cross-aggregate)
const failures = await eventStore.getEventsByType(EventType.TaskFailed);

// Swarm-internal replay from a point in time
const recent = queen.getEventHistory(cutoffISOTimestamp);
```

---

## Data Flow

The following describes a complete task execution cycle.

```
 User
   │
   ▼
 CLI (a3ro task create ...)
   │  creates Task domain object
   ▼
 OrchestratorEngine.dispatch(task, swarmId)
   │  writes task:{id} → IMemoryService
   │  emits TaskAssigned → IEventStore
   ▼
 SwarmCoordinator.getSwarm(swarmId)
   │  validates swarm exists and is running
   ▼
 QueenCoordinator.dispatchTask(task)   [inside swarm]
   │  appends task.dispatched → SwarmEventStore
   ▼
 QueenCoordinator.spawn(role, config)   [if agent needed]
   │  creates Agent domain object
   │  appends agent.spawned → SwarmEventStore
   ▼
 BaseAgent.execute(task)   [Session 3: calls Anthropic SDK]
   │  may call Tools via ToolRegistry
   │  writes intermediate state to IMemoryService
   │  sends messages via ITransportChannel (to peers)
   ▼
 OrchestratorEngine.complete(taskId, output)
   │  updates task:{id} in IMemoryService (status=completed)
   │  emits TaskCompleted → IEventStore
   ▼
 CLI (a3ro task list / a3ro status)
   │  reads from IMemoryService + ISwarmCoordinator
   ▼
 OutputFormatter → stdout (text or JSON)
```

### Security boundary

All external input (user CLI args, API payloads in Session 4) passes through `@a3ro/security` before reaching the orchestration layer:

```
External input
   │
   ▼
 InputValidator.validateAgentInput(input)
   ├─ AgentInputSchema (Zod)     — length, type
   ├─ detectInjection(input)     — 20 prompt-injection patterns
   └─ scanPII(input)             — 10 PII detector regexes
   │
   ├─ threats.length > 0 → reject with threat list
   └─ threats.length === 0 → forward to OrchestratorEngine
```

### Memory namespacing

```
Namespace          Key pattern        Contents
─────────────────  ─────────────────  ────────────────────────────
"agents"           <agentId>          Agent context and working memory
"tasks"            task:<taskId>      Task state (OrchestratorEngine)
"swarms"           <swarmId>          Swarm metadata cache
"tools"            tool:<name>        Tool result cache
"sessions"         session:<id>       Cross-agent session state
```

---

## Dependency Graph

Package build order is enforced via TypeScript `composite` project references:

```
@a3ro/types
  └── @a3ro/config
  └── @a3ro/formatter
        └── @a3ro/cli
  └── @a3ro/memory
        └── @a3ro/swarm ──── @a3ro/memory
              └── @a3ro/orchestrator ──── @a3ro/swarm
                                     └── @a3ro/memory
                                     └── @a3ro/events
  └── @a3ro/agent
        └── @a3ro/tools
  └── @a3ro/events
  └── @a3ro/plugins
  └── @a3ro/transport
  └── @a3ro/telemetry

@a3ro/security   (no @a3ro/* deps — depends only on zod)
```

`@a3ro/security` is deliberately isolated — it has no dependency on any other A3RO package so it can be used as an upstream guard without creating circular dependencies.
