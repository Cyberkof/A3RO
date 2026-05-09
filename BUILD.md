# A3RO Build & Development Guide

---

## Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Node.js | 20.0.0 | `node --version` to check |
| pnpm | 9.0.0 | `npm i -g pnpm@9` |
| TypeScript | 5.6 | installed as a dev dep; no global required |

Both Node.js and pnpm versions are enforced at install time via `engines` in `package.json` and `engine-strict=true` in `.npmrc`. If the wrong version is active you will see an error before install completes.

---

## Installation

```bash
# Clone and enter the repo
git clone <repo-url> a3ro
cd a3ro

# Install all workspace dependencies
pnpm install
```

pnpm hoists common packages to `node_modules/` at the root and links each `packages/*` workspace so that `@a3ro/*` imports resolve locally without publishing.

---

## Building

### Build all packages

```bash
pnpm run build
```

This runs `tsc -p tsconfig.json` in each package in dependency order (enforced by TypeScript `composite` project references). Output lands in `packages/<name>/dist/`.

### Build a single package

```bash
cd packages/memory
pnpm run build
```

### Build with esbuild (bundled single file)

The root `esbuild.config.ts` bundles one package into a self-contained ESM file. Useful for distribution or quick local debugging:

```bash
# Example: bundle @a3ro/cli
node --import tsx/esm esbuild.config.ts cli
# Output: packages/cli/dist/index.js  (bundled)
```

> `tsx` must be available (`pnpm add -g tsx`). The esbuild path is intended for CI artefacts, not day-to-day development.

### Typecheck without emitting

```bash
pnpm run typecheck
```

Runs `tsc --noEmit` across all packages via pnpm's recursive `-r` flag. Useful in CI to catch type errors without modifying `dist/`.

### Clean

```bash
pnpm run clean
```

Removes all `dist/` directories and the root `node_modules/`. Run before a fresh install if you suspect stale build artefacts.

---

## Development Workflow

### Incremental watch build

TypeScript project references support incremental builds. Open a terminal and run:

```bash
pnpm -r --parallel exec tsc -p tsconfig.json --watch
```

Each package rebuilds only what changed. Keep this running in a background terminal while developing.

### Working on a single package

```bash
cd packages/security
# Edit src files ...
pnpm run typecheck        # fast type-check
pnpm run test             # run this package's tests only
```

### Adding a dependency between packages

1. Add the dependency to the package's `package.json`:
   ```json
   "dependencies": { "@a3ro/types": "workspace:*" }
   ```
2. Add a project reference to the package's `tsconfig.json`:
   ```json
   { "references": [{ "path": "../../types" }] }
   ```
3. Run `pnpm install` from the root to update the lockfile.

### Adding a new package

1. Create `packages/<name>/` with `src/index.ts`, `package.json`, `tsconfig.json`
2. Use `packages/security/` as a template for self-contained packages; use `packages/memory/` as a template for packages that depend on `@a3ro/types`
3. Add a reference to the root `tsconfig.json`
4. Run `pnpm install` from the root

---

## Testing

### Run all tests

```bash
pnpm run test
```

Uses the root `vitest.config.ts` which discovers every `packages/*/tests/**/*.test.ts` file.

### Watch mode

```bash
pnpm run test:watch
```

Vitest re-runs affected tests on every file save. Essential during TDD cycles.

### Coverage report

```bash
pnpm run test:coverage
```

Generates:
- `coverage/index.html` — interactive browser report
- `coverage/lcov.info` — for CI integration (Codecov, SonarQube)

Coverage is collected from `packages/*/src/**` excluding barrel `index.ts` files.

### Test a single package

```bash
cd packages/swarm
pnpm run test
```

Or scope from the root:

```bash
pnpm vitest run packages/swarm/tests
```

### Test patterns

- All tests use **Vitest** with `globals: true` (no explicit `import { describe, it, expect }` required, but we import explicitly for IDE support)
- Tests follow **London School TDD**: external dependencies are mocked via `vi.fn()` and interactions are verified with `toHaveBeenCalledWith`
- Side effects on `process.stdout` / `process.stderr` are asserted via `vi.spyOn` with `mockImplementation(() => true)`
- `beforeEach` + `afterEach` ensure test isolation; never share mutable state between test cases

### Test file locations

| Package | Test file |
|---|---|
| `@a3ro/types` | `packages/types/tests/validation.test.ts` |
| `@a3ro/cli` | `packages/cli/tests/cli.test.ts`, `output.test.ts` |
| `@a3ro/swarm` | `packages/swarm/tests/coordinator.test.ts`, `event-store.test.ts`, `swarm.test.ts` |
| `@a3ro/memory` | `packages/memory/tests/memory.test.ts` |
| `@a3ro/config` | `packages/config/tests/config.test.ts`, `loader.test.ts` |
| `@a3ro/security` | `packages/security/tests/validation.test.ts` |

---

## Debugging

### Enable debug output in the CLI

```bash
a3ro --debug <command>
```

Sets `OutputFormatter` to `LogLevel.DEBUG`, which emits all internal trace messages prefixed with a purple hexagon (`⬡`).

### Inspect config resolution

```bash
A3RO_LOG_LEVEL=debug a3ro status
```

To see exactly which config file is being loaded and which env vars are active, temporarily add a `console.error` in `packages/config/src/loader.ts:readFileConfig`.

### Trace event emission

The `OrchestratorEngine` accepts an optional `IEventStore`. Pass `InMemoryEventStore` and inspect it after operations:

```typescript
import { InMemoryEventStore } from '@a3ro/events';
import { OrchestratorEngine } from '@a3ro/orchestrator';

const events = new InMemoryEventStore();
const engine = new OrchestratorEngine({ swarm, memory, events });

// ... run operations ...

const all = await events.getEvents('system');
console.log(all.map(e => `${e.type} v${e.version}`));
```

### Replay swarm history

`QueenCoordinator` exposes its internal `EventStore`:

```typescript
const queen = new QueenCoordinator();
// ... spawn agents, dispatch tasks ...

const history = queen.getEventHistory();
// or from a point in time:
const recent = queen.getEventHistory(new Date(Date.now() - 5000).toISOString());
```

### Node.js inspector

```bash
node --inspect-brk packages/cli/dist/bin.js agent list
# Then open chrome://inspect in Chrome
```

### Memory diagnostics

```typescript
import { createBackend } from '@a3ro/memory';
const backend = createBackend('in-memory');
await backend.store('debug', 'probe', { ts: Date.now() });
const results = await backend.search('debug', 'probe', 100);
console.log(results);
```

---

## CI Checklist

Before merging a PR, verify:

```bash
pnpm install          # lockfile is consistent
pnpm run typecheck    # zero TypeScript errors
pnpm run test         # all tests pass
pnpm run build        # all packages emit to dist/
```

The recommended CI sequence (GitHub Actions example):

```yaml
- uses: pnpm/action-setup@v4
  with: { version: 9 }
- uses: actions/setup-node@v4
  with: { node-version: '20', cache: 'pnpm' }
- run: pnpm install --frozen-lockfile
- run: pnpm run typecheck
- run: pnpm run test:coverage
- run: pnpm run build
```

---

## Common Issues

**`ERR_MODULE_NOT_FOUND` for `@a3ro/*`**
Run `pnpm install` from the root. The workspace symlinks are missing — this happens after a `clean` or fresh checkout.

**`tsc` reports "project reference must be enabled"`**
Each package's `tsconfig.json` must extend `../../tsconfig.base.json` which sets `"composite": true`. Check the tsconfig of the affected package.

**Tests import `.js` extensions but source is `.ts`**
This is intentional. The project uses `"module": "Node16"` which requires explicit `.js` extensions in ESM imports even when the source is TypeScript. Vitest resolves `.ts` for `.js` imports automatically at test time.

**`vitest: globals are not defined`**
The root `vitest.config.ts` sets `globals: true`. If you're running Vitest from a package directory directly, ensure it picks up the root config: `vitest run --config ../../vitest.config.ts`.
