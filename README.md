# A3RO — AI Agent Orchestration Platform

A3RO is a TypeScript monorepo for building, coordinating, and running autonomous multi-agent systems on top of Claude. It provides a CLI, a swarm coordinator, a memory layer, an event-sourced audit trail, and a plugin system — all as composable, independently publishable packages.

---

## What is A3RO?

A3RO ("Aero") lets you:

- **Spawn agent swarms** — create named groups of specialist AI agents that collaborate under configurable topologies (hierarchical, mesh, ring, star, adaptive)
- **Orchestrate tasks** — dispatch work items to swarms, track lifecycle from `pending` through `completed` or `failed`, and query active state at any time
- **Persist memory** — store and retrieve agent context across a namespace-scoped memory layer; vector search (HNSW) arrives in Session 3
- **Audit everything** — every state transition emits a versioned event to an append-only event store so you can replay system history
- **Secure inputs** — validate agent inputs with Zod schemas, scan for prompt injection attacks, and detect PII before it reaches a model
- **Extend freely** — load tools and plugins at runtime through the plugin registry without modifying core packages

The platform is intentionally headless. The CLI is the primary entry point today; a REST/WebSocket API layer is planned for Session 4.

---

## Quick Start

**Prerequisites:** Node.js >= 20, pnpm >= 9

```bash
# 1. Install dependencies
pnpm install

# 2. Build all packages (TypeScript → dist/)
pnpm run build

# 3. Run the full test suite
pnpm run test

# 4. Run tests with coverage
pnpm run test:coverage

# 5. Type-check without emitting
pnpm run typecheck
```

After building, the CLI binary is available via the `@a3ro/cli` package:

```bash
# Using the built binary directly
node packages/cli/dist/bin.js --help

# Or link it globally (optional)
cd packages/cli && pnpm link --global
a3ro --help
```

### CLI tour

```bash
# Agent commands
a3ro agent create --name my-agent --role core_architect
a3ro agent list
a3ro agent start <id>
a3ro agent stop <id>

# Swarm commands
a3ro swarm create --name my-swarm --topology hierarchical
a3ro swarm list
a3ro swarm start <id>
a3ro swarm add-agent <swarm-id> <agent-id>

# Task commands
a3ro task create --name "Analyse codebase" --priority 7
a3ro task list

# Memory commands
a3ro memory set <key> <value>
a3ro memory get <key>

# System
a3ro status
a3ro version
```

### Output modes

All commands accept global flags:

| Flag | Effect |
|---|---|
| `--json` | Emit structured JSON (pipe-friendly) |
| `-q, --quiet` | Suppress all non-error output |
| `-v, --verbose` | Show verbose progress messages |
| `--debug` | Maximum verbosity including internal trace |
| `--config <path>` | Load config from an explicit file path |

---

## Monorepo Structure

```
a3ro/
├── packages/
│   ├── types/          @a3ro/types          — Zod schemas, domain types, enums, interfaces
│   ├── config/         @a3ro/config         — Config loading, env-var merging, validation
│   ├── formatter/      @a3ro/formatter      — Lightweight IFormatter implementation
│   ├── cli/            @a3ro/cli            — CLI entry point, commands, OutputFormatter
│   ├── memory/         @a3ro/memory         — Namespace-scoped MemoryService + QueryBuilder
│   ├── swarm/          @a3ro/swarm          — SwarmCoordinator, QueenCoordinator, EventStore
│   ├── agent/          @a3ro/agent          — BaseAgent abstract class + lifecycle hooks
│   ├── tools/          @a3ro/tools          — Tool registry (ITool interface)
│   ├── events/         @a3ro/events         — InMemoryEventStore (IEventStore)
│   ├── plugins/        @a3ro/plugins        — Plugin loader and registry
│   ├── transport/      @a3ro/transport      — InProcessChannel (ITransportChannel)
│   ├── orchestrator/   @a3ro/orchestrator   — OrchestratorEngine (task dispatch + lifecycle)
│   ├── telemetry/      @a3ro/telemetry      — Structured logger
│   └── security/       @a3ro/security       — InputValidator, injection detection, PII scan
├── tsconfig.base.json  — Shared TypeScript compiler options
├── tsconfig.json       — Root project references
├── vitest.config.ts    — Unified test runner config
├── esbuild.config.ts   — Single-package bundler helper
├── pnpm-workspace.yaml — Workspace declaration
└── package.json        — Root scripts
```

Each package under `packages/` is an independent `@a3ro/*` workspace package with its own `tsconfig.json`, `package.json`, and `tests/` directory.

---

## Configuration

A3RO searches for config in this order (last wins):

1. Built-in defaults (`packages/config/src/defaults.ts`)
2. Config file — first found among `.claude/settings.json`, `.a3ro/config.json`, `a3ro.config.json` relative to `$A3RO_HOME` or `cwd`
3. Environment variables (`A3RO_*` / `ANTHROPIC_*`)

Key environment variables:

| Variable | Config key | Default |
|---|---|---|
| `ANTHROPIC_API_KEY` | `apiKey` | — |
| `A3RO_DEFAULT_MODEL` | `defaultModel` | `claude-opus-4-7` |
| `A3RO_OUTPUT_FORMAT` | `outputFormat` | `text` |
| `A3RO_LOG_LEVEL` | `logLevel` | `info` |
| `A3RO_MAX_RETRIES` | `maxRetries` | `3` |
| `A3RO_TELEMETRY` | `telemetry` | `true` |
| `A3RO_MAX_CONCURRENT_AGENTS` | `maxConcurrentAgents` | `10` |
| `A3RO_DEFAULT_TOPOLOGY` | `defaultTopology` | `hierarchical` |
| `A3RO_MEMORY_BACKEND` | `memoryBackend` | `in_memory` |

---

## Next Steps — Session 3

The Session 2 foundation is complete:

- [x] Memory service with namespace API and `QueryBuilder`
- [x] Security package — injection detection, PII scanning, `InputValidator`
- [x] Comprehensive test suite across all 14 packages

Session 3 will deliver:

- [ ] **HNSW vector search** — replace substring scan in `InMemoryBackend` with an approximate nearest-neighbour index; expose `similarityThreshold` in `QueryBuilder`
- [ ] **Anthropic SDK integration** — wire `BaseAgent.execute()` to `@anthropic-ai/sdk` with streaming, retries, and token accounting
- [ ] **Tool execution pipeline** — connect the tool registry to `BaseAgent` so agents can call tools mid-task
- [ ] **REST/WebSocket API** — expose orchestration over HTTP so external systems can dispatch tasks
- [ ] **Redis memory backend** — production-grade persistent memory via `@a3ro/memory` backend factory

---

## License

MIT
