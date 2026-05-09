# A3RO Dashboard — Complete Build Brief for Claude Code

## Table of Contents
1. [Project Overview](#project-overview)
2. [Aesthetic Direction](#aesthetic-direction)
3. [Design Tokens](#design-tokens)
4. [Architecture & Tech Stack](#architecture--tech-stack)
5. [Component Specifications](#component-specifications)
6. [Data Flow & Integration](#data-flow--integration)
7. [File Structure](#file-structure)
8. [Implementation Checklist](#implementation-checklist)
9. [Prompt for Claude Code](#prompt-for-claude-code)

---

## Project Overview

**Goal:** Build a real-time web-based monitoring dashboard for the A3RO AI Agent Orchestration Platform that visualizes swarm topology, agent lifecycle, task dispatch, memory operations, security events, and audit logs as they happen.

**Key Requirement:** The dashboard must work **standalone with mock data** while remaining ready to connect to a live WebSocket backend.

**Users:** Developers, security engineers, and DevOps teams monitoring AI agent swarms in development and production.

---

## Aesthetic Direction

### Core Vision
**Ethereal Holographic Command Center** — luminous, spacious, dreamy. Like monitoring a digital crystal palace from inside a cloud.

**Inspiration Board:** Soft glows, light rays, luminescent cores, cool palettes (ice blues, cyans, purples, whites), crystalline geometries, holographic/AR vibes, minimalist elegance.

**NOT:** Dark gritty cyberpunk terminal with harsh neon. **YES:** Dreamy, breathing, luminous, with plenty of whitespace.

---

## Design Tokens

### Color Palette

| Element | Hex Value | RGB / Usage |
|---------|-----------|------------|
| **Background (Base)** | `#0f1729` | Very dark blue, almost black with cool undertone |
| **Primary Accent** | `#4dd0e1` | Luminous cyan — use for active states, glows, primary UI |
| **Secondary Accent** | `#b39ddb` | Soft lavender/purple — use for secondary labels, muted states |
| **Tertiary Accent** | `#81d4fa` | Ice blue — use for data values, highlights |
| **Success/Active** | `#80deea` | Pale cyan glow — agent running, task complete |
| **Alert/Error** | `#ff6ec7` | Soft magenta — errors, blocks, warnings (not harsh red) |
| **Text Primary** | `#e8f4f8` | Cool white — readable on dark background |
| **Text Secondary** | `#b0bec5` | Cool gray — muted labels, secondary info |
| **Border/Grid** | `rgba(77, 208, 225, 0.15)` | Soft cyan with transparency |
| **Glow (Active)** | `rgba(77, 208, 225, 0.4)` | Cyan glow for elevated elements |
| **Glow (Alert)** | `rgba(255, 110, 199, 0.3)` | Soft magenta glow for warnings |

### Typography

- **Monospace Font:** `'IBM Plex Mono'`, fallback `'Space Mono'`, then `'Courier New'`
  - All data, timestamps, IDs, and technical values in monospace
- **Status Text:** `#80deea` (cyan) for active/running states
- **Labels:** `#b39ddb` (soft purple) for secondary text
- **Data Values:** `#e8f4f8` (cool white) for important numbers
- **Line Height:** `1.6–1.8` (airy, not cramped)

### Spacing & Layout

- **Gutters:** `20–24px` (more breathing room than standard)
- **Panel Margins:** `16px`
- **Card Padding:** `24px` (generous)
- **Grid Gaps:** Larger, emphasize separation
- **Border Radius:** `rounded-xl` or `12–16px` (soft corners, no hard edges)

---

## Architecture & Tech Stack

### Frontend Framework
- **Framework:** React 18+ (functional components, hooks)
- **Styling:** Tailwind CSS + custom CSS for neon/glow effects
- **State Management:** React Context API or Zustand (lightweight, WebSocket-friendly)
- **Build Tool:** Vite or Create React App

### Visualization Libraries
- **Graph/Topology:** `react-flow-renderer` (hierarchical layout) or `cytoscape.js`
- **Charts:** `recharts` (lightweight, animation-friendly) or `chart.js`
- **Icons:** `lucide-react` (clean, minimal SVGs)
- **Animations:** Tailwind CSS `animate-*` utilities + CSS keyframes

### Data & Integration
- **WebSocket:** Native `WebSocket` API or `socket.io-client` (for fallback)
- **Mock Data:** Custom generator (`mockDataGenerator.js`) that emulates real event stream
- **State Updates:** React hooks (`useState`, `useEffect`, `useCallback`)
- **Event Parsing:** Custom utility (`eventParser.js`) to normalize incoming data

### Development Environment
- **Node:** 16+ (for npm/yarn)
- **Package Manager:** npm or yarn
- **Environment Variables:** `.env` file for backend URL, WebSocket endpoint

---

## Component Specifications

### 1. **SwarmStatus** Component
**Purpose:** Display real-time swarm health and metadata at a glance.

**Data Displayed:**
- Swarm name + ID (first 8 characters)
- Topology type (hierarchical, mesh, peer)
- Current status (idle, running, paused, error)
- Live agent count (e.g., "4 / 4 active")
- Uptime counter (HH:MM:SS format, auto-incrementing)

**Visual Design:**
- Floating holographic card with generous padding (`24px`)
- Large luminous number (agent count) in cyan (`#4dd0e1`), font-size `32–40px`
- Status indicator: Soft glow (pulsing opacity, not color shift)
  - Running: `#80deea` (pale cyan) with glow
  - Idle: `#b39ddb` (muted purple)
  - Error: `#ff6ec7` (soft magenta)
- Uptime as delicate counter in ice-blue (`#81d4fa`)
- Background: `rgba(15, 23, 41, 0.6)` with `backdrop-filter: blur(20px)`
- Border: `1px solid rgba(129, 212, 250, 0.3)`
- Glow: `box-shadow: 0 0 30px rgba(77, 208, 225, 0.1), inset 0 1px 0 rgba(255,255,255,0.1)`

**Animations:**
```css
@keyframes softGlow {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}
```

**Interactive Features:**
- Hover: Glow intensity increases slightly
- Click (optional): Show detailed swarm stats in modal

---

### 2. **AgentTopology** Component
**Purpose:** Visualize agent network structure and message flow in real-time.

**Data Displayed:**
- Nodes: Individual agents (core_architect, security_architect, test_engineer, debugger)
- Each node shows: Role icon + agent name + status dot + uptime
- Edges: Message channels with directional arrows
- Layout: Hierarchical/tree (Queen at top, agents below)

**Visual Design:**
- **Nodes:**
  - Size: `18–24px` circles
  - Active (running): Cyan glow (`#4dd0e1`) with soft shadow
  - Idle: Muted purple (`#b39ddb`)
  - Error: Soft magenta (`#ff6ec7`)
  - Inner glow: `box-shadow: 0 0 12px rgba(77, 208, 225, 0.6), inset 0 0 8px rgba(77, 208, 225, 0.3)`
- **Edges:**
  - Stroke: `rgba(129, 212, 250, 0.5)` (soft cyan)
  - Blur filter: `drop-shadow(0 0 4px rgba(77, 208, 225, 0.6))`
  - Smooth curves (not straight lines)
  - Arrows: Small directional markers on message flow
- **Labels:** Float above nodes in pale text (`#e8f4f8`), monospace font, small size
- **Background:** Subtle gradient or distant nebula (optional particle field)

**Animations:**
- Message flow: Animated dashes moving along edges (slow, subtle)
- Node glow: Pulsing opacity on active nodes
- Hover effect: Glow intensifies, show connection details in tooltip

**Interactive Features:**
- Hover over node: Show tooltip with agent details (role, uptime, messages sent/received, last message time)
- Click on node: Open agent detail modal (optional)
- Drag to reposition (optional, for UX flexibility)

---

### 3. **AgentRoster** Component
**Purpose:** Display list of all agents with status and metrics.

**Data Displayed:**
- Columns: Role | Name | Status | Uptime | Message Count | Last Active
- Sortable by any column
- Color-coded status dots

**Visual Design:**
- Table with transparent rows
- Row hover: Soft glow, neon borders
- Status dots: Color-coded (cyan for active, purple for idle, magenta for error)
- Monospace font for all data
- Padding: `16px` per cell

**Animations:**
- New agent rows: Fade-in + slide from top
- Status changes: Smooth color transition

**Interactive Features:**
- Sort by column (click header)
- Filter by role (optional dropdown)
- Hover row: Show more details in tooltip

---

### 4. **MemoryBrowser** Component
**Purpose:** Inspect A3RO memory service namespaces and stored data.

**Data Displayed:**
- Collapsible namespace tree: `agents` → `tasks` → `sessions` → `vectors`
- Count per namespace (e.g., `agents (4)`)
- Last accessed timestamp per namespace
- Click namespace → show sample keys in detail panel below

**Visual Design:**
- Accordion-style, smooth expand/collapse
- Folder icons: Minimalist, with soft glow (`#b39ddb`)
- Counts shown in ice-blue badges (`#81d4fa`)
- Lots of whitespace between sections
- Detail panel: Shows 5–10 sample keys with timestamps

**Animations:**
- Expand/collapse: Smooth height transition (300ms)
- Key fade-in: Staggered delay for each key in detail panel

**Interactive Features:**
- Click to expand/collapse namespaces
- Click on namespace → scroll detail panel to that section
- (Optional) Search across namespaces

---

### 5. **SecurityMonitor** Component
**Purpose:** Real-time threat detection and security event monitoring.

**Data Displayed:**
- Threat counter (total blocks vs. allows lifetime)
- Stacked bar chart: ALLOW (cyan) vs. BLOCK (magenta) distribution
- Live threat feed:
  - Row per event: `[timestamp] [type: injection/pii/jailbreak] [status: BLOCK/ALLOW] [details snippet]`

**Visual Design:**
- **Chart:**
  - Horizontal bar with soft gradient (cyan → lavender)
  - Translucent, glowing edge
  - Labels in monospace
- **Threat Feed:**
  - Minimalist list layout (1 row per event)
  - BLOCK: Soft magenta glow (`#ff6ec7`), left border in magenta
  - ALLOW: Pale cyan glow (`#80deea`), left border in cyan
  - Age-based fade: New entries bright, older entries dim
  - Monospace font for all data
- **Overall:** Spacious, not cramped

**Animations:**
- New threat entry: Fade-in + slide from top (300ms)
- Chart updates: Smooth bar transition (500ms)
- Entry aging: Opacity fade over 10 seconds

**Interactive Features:**
- Hover threat row: Show full details in expanded tooltip
- Click threat row (optional): Filter event log to related events
- Pause/resume feed (optional button)

---

### 6. **TaskOrchestrator** Component
**Purpose:** Track task execution, priority, and completion status.

**Data Displayed:**
- Active tasks: ID | Name | Priority (0–10) | Status | Score (0–100)
- Task timeline: Show state progression (dispatched → in_progress → completed)
- Sort by priority or status, filter options

**Visual Design:**
- **Task Cards:**
  - Border-left: Color-coded by priority
    - Priority 0–3 (low): Blue (`#4dd0e1`)
    - Priority 4–6 (medium): Cyan (`#81d4fa`)
    - Priority 7–10 (high): Lavender (`#b39ddb`)
  - Progress bar: Translucent with glowing edge
  - Padding: `16px`
  - Spacing: `12px` between cards
- **Timeline:**
  - Horizontal layout, minimal
  - Milestone markers (dispatched, in_progress, completed) in soft cyan
  - Connecting line: Soft gradient

**Animations:**
- Task completion: Progress bar fills (smooth, 1s)
- New task: Card fade-in + slide from left
- Status change: Smooth color transition

**Interactive Features:**
- Click card: Show full task details (name, priority, dependencies, estimated time, current activity)
- Filter by status (showing only active, or only completed, etc.)
- Sort by priority or time

---

### 7. **EventLog** Component
**Purpose:** Real-time audit trail of all system, task, and agent events.

**Data Displayed:**
- Auto-scrolling feed of events
- Columns: Timestamp | Aggregate Type | Event Type | Payload (JSON snippet)
- Auto-scrolls to latest; user can pause

**Visual Design:**
- Dark background, monospace text
- Color-coded by aggregate:
  - System: Cyan (`#4dd0e1`)
  - Task: Lavender (`#b39ddb`)
  - Agent: Ice blue (`#81d4fa`)
- New entries: Bright glow, fade out as they age
- Row hover: Soft glow highlight
- Padding: `12px` per row, `16px` top/bottom

**Animations:**
- New entry: Fade-in + slide from top (200ms)
- Age-based fade: Opacity decreases over 30 seconds
- Auto-scroll: Smooth scroll to bottom (300ms)

**Interactive Features:**
- Hover row: Show full JSON payload in tooltip or expand
- Click row: Copy timestamp or event details to clipboard (optional)
- Pause button: Stop auto-scroll (shows scroll position)
- Clear button: Clear old entries (optional)

---

### 8. **TransportMetrics** Component
**Purpose:** Monitor message throughput and channel health (optional, collapsible).

**Data Displayed:**
- Message throughput (msgs/sec, average over last 60s)
- Active channels count
- Message types distribution (COMMAND, DATA, STATUS) — pie or bar chart
- Inbox depth per agent (bar chart)

**Visual Design:**
- Compact metrics row (can be full width or grid)
- Inline sparklines for throughput trend
- Small bar charts for inbox depth
- Color-coded message types

**Animations:**
- Sparklines update in real-time
- Throughput number animates on change

**Interactive Features:**
- Hover sparkline: Show detailed history (tooltip)
- Click to expand/collapse section (optional)

---

## Data Flow & Integration

### Mock Data Generator (`mockDataGenerator.js`)

The dashboard includes a **mock WebSocket event generator** that emulates real A3RO backend data. This ensures the dashboard works **standalone without a backend**.

**Generates:**
1. **Swarm events** (create, start, pause, error)
2. **Agent events** (spawn, status_changed, heartbeat)
3. **Task events** (dispatched, in_progress, completed)
4. **Security events** (ALLOW, BLOCK with threat type)
5. **Memory events** (stored, retrieved, deleted)
6. **Transport events** (message sent, channel opened/closed)

**Behavior:**
- Emits events at realistic intervals (not all at once)
- Event timestamps are accurate (millisecond precision)
- Supports ~30–40 events per session to simulate real workload
- Can be toggled on/off via environment variable (`REACT_APP_USE_MOCK_DATA=true`)

### WebSocket Connection Hook (`useWebSocket.js`)

Custom React hook that:
- Connects to backend WebSocket (configurable URL)
- Falls back to mock data if connection fails or mock is enabled
- Handles reconnection logic (exponential backoff)
- Provides `events` stream and `status` (connected/disconnected)
- Cleanup on unmount

```javascript
const { events, status, disconnect } = useWebSocket();
// events = stream of parsed A3RO events
// status = 'connected' | 'disconnected' | 'connecting'
```

### Event Parser (`eventParser.js`)

Normalizes incoming events to a consistent schema:

```javascript
{
  id: string,              // unique event ID
  timestamp: number,       // milliseconds since epoch
  aggregate: 'system' | 'task' | 'agent' | 'security' | 'memory' | 'transport',
  type: string,            // event type (e.g., 'agent.spawned')
  payload: object,         // event data
  severity: 'info' | 'warning' | 'error'
}
```

---

## File Structure

```
a3ro-dashboard/
├── public/
│   ├── index.html
│   └── favicon.ico
├── src/
│   ├── components/
│   │   ├── SwarmStatus.jsx
│   │   ├── AgentTopology.jsx
│   │   ├── AgentRoster.jsx
│   │   ├── MemoryBrowser.jsx
│   │   ├── SecurityMonitor.jsx
│   │   ├── TaskOrchestrator.jsx
│   │   ├── EventLog.jsx
│   │   ├── TransportMetrics.jsx
│   │   └── Layout.jsx (main dashboard grid)
│   ├── hooks/
│   │   ├── useWebSocket.js
│   │   ├── useMockData.js
│   │   └── useLocalStorage.js (for state persistence)
│   ├── utils/
│   │   ├── mockDataGenerator.js
│   │   ├── eventParser.js
│   │   ├── colorMap.js
│   │   └── formatters.js (timestamps, numbers, etc.)
│   ├── styles/
│   │   ├── globals.css (base layout, animations, grid)
│   │   ├── theme.css (design tokens, color vars)
│   │   └── components.css (glow effects, borders)
│   ├── App.jsx (main app)
│   └── index.jsx (entry point)
├── .env.example
├── package.json
├── tailwind.config.js
├── vite.config.js (or react-scripts if using CRA)
└── README.md
```

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Create React project (Vite or CRA)
- [ ] Install dependencies (React, Tailwind, recharts, react-flow, lucide-react)
- [ ] Configure Tailwind with custom colors (design tokens)
- [ ] Set up folder structure

### Phase 2: Styling & Theme
- [ ] Create `theme.css` with CSS variables for all colors
- [ ] Create `globals.css` with base layout, grid, animations
- [ ] Create `components.css` with glow/blur effects
- [ ] Test color palette on light/dark backgrounds

### Phase 3: Mock Data & Hooks
- [ ] Build `mockDataGenerator.js` (generate realistic events)
- [ ] Build `useWebSocket.js` hook (WebSocket + fallback)
- [ ] Build `useMockData.js` hook (control mock data flow)
- [ ] Build `eventParser.js` (normalize events)
- [ ] Test event stream with console logs

### Phase 4: Layout & Core Components
- [ ] Build `Layout.jsx` (main grid, responsive)
- [ ] Build `SwarmStatus.jsx` (simple, no graph)
- [ ] Build `AgentRoster.jsx` (table)
- [ ] Build `EventLog.jsx` (scrolling list)
- [ ] Build `MemoryBrowser.jsx` (accordion)
- [ ] Test layout on desktop & tablet

### Phase 5: Visualization Components
- [ ] Build `AgentTopology.jsx` (react-flow or cytoscape)
- [ ] Build `SecurityMonitor.jsx` (recharts bars + threat feed)
- [ ] Build `TaskOrchestrator.jsx` (progress cards + timeline)
- [ ] Build `TransportMetrics.jsx` (sparklines, mini charts)

### Phase 6: Polish & Animation
- [ ] Add smooth transitions between state changes
- [ ] Add pulsing/glow animations to active elements
- [ ] Test animations on real event stream (not too slow, not jarring)
- [ ] Add fade-out for old log entries
- [ ] Ensure accessibility (contrast, focus states)

### Phase 7: Configuration & Deployment
- [ ] Create `.env` file with backend URL (default to mock)
- [ ] Add environment toggle (REACT_APP_USE_MOCK_DATA)
- [ ] Test graceful fallback when WebSocket unavailable
- [ ] Build for production (`npm run build`)
- [ ] Document deployment steps in README

---

## Prompt for Claude Code

Copy and paste this prompt into Claude Code:

---

### **Claude Code Prompt**

```
Build a real-time web dashboard for A3RO (AI Agent Orchestration Platform) with the following specifications:

## AESTHETIC DIRECTION
- Ethereal, holographic command center (NOT dark cyberpunk)
- Luminous, spacious, dreamy aesthetic
- Soft glows, ice blues, cyans, purples, whites
- Plenty of whitespace and breathing room
- Minimalist elegance, glassmorphic panels

## DESIGN TOKENS
- Background: #0f1729 (very dark blue)
- Primary Accent: #4dd0e1 (luminous cyan)
- Secondary: #b39ddb (soft lavender)
- Tertiary: #81d4fa (ice blue)
- Success: #80deea (pale cyan glow)
- Alert: #ff6ec7 (soft magenta, not harsh red)
- Text: #e8f4f8 (cool white)
- Border: rgba(77, 208, 225, 0.15) (soft cyan)
- All fonts monospace: IBM Plex Mono or Space Mono
- Spacing generous: 20-24px gutters, 24px card padding
- Border radius: 12-16px (soft corners)

## COMPONENTS TO BUILD

1. **SwarmStatus** — Swarm name, ID, status (idle/running/paused), agent count, uptime counter
   - Large luminous cyan number for agent count
   - Pulsing status indicator (opacity fade, not color shift)
   - Glowing card: box-shadow with inner + outer glow

2. **AgentTopology** — Hierarchical agent network graph
   - Use react-flow-renderer or cytoscape.js
   - Nodes: 18-24px circles with cyan glow (active) or purple (idle)
   - Edges: Soft cyan curved lines with animated flow
   - Hover: Show agent details in tooltip
   - Background: Optional subtle particle field

3. **AgentRoster** — Table of all agents (Role, Name, Status, Uptime, Message Count)
   - Color-coded status dots
   - Sortable columns, hover glow effect
   - Monospace font for all data

4. **MemoryBrowser** — Collapsible namespace tree (agents, tasks, sessions, vectors)
   - Show count per namespace
   - Accordion-style expand/collapse with smooth animation
   - Detail panel below showing sample keys

5. **SecurityMonitor** — Threat detection dashboard
   - Stacked bar chart (ALLOW vs BLOCK) with soft gradient colors
   - Live threat feed with timestamp, type, status, details
   - BLOCK = soft magenta glow, ALLOW = pale cyan glow
   - New entries fade-in + slide from top

6. **TaskOrchestrator** — Task execution tracking
   - Cards with priority-coded left border (blue/cyan/purple gradient)
   - Progress bar with glowing edge
   - Timeline showing state progression
   - Sort/filter options

7. **EventLog** — Real-time audit trail
   - Auto-scrolling monospace list
   - Color-coded by aggregate: system=cyan, task=lavender, agent=ice-blue
   - New entries bright, age-based fade
   - Hover to expand full JSON payload

8. **TransportMetrics** (optional) — Message throughput, channel health
   - Inline sparklines, mini bar charts
   - Color-coded message types

## DATA INTEGRATION

- Include **mock WebSocket event generator** (mockDataGenerator.js) so dashboard works standalone
- Custom useWebSocket hook with fallback to mock data if backend unavailable
- Event parser that normalizes all events to consistent schema
- All components react to incoming events in real-time

## TECHNICAL REQUIREMENTS

- React 18+ functional components with hooks
- Tailwind CSS + custom CSS for glows/animations
- recharts for charts, react-flow for topology graph, lucide-react for icons
- Vite for build tool
- CSS animations: pulsing opacity, smooth fade-in, staggered delays
- Responsive layout (desktop-first, tablet-friendly)
- glassmorphic panels: rgba(15, 23, 41, 0.6) + backdrop-filter: blur(20px)
- All borders soft cyan: 1px solid rgba(129, 212, 250, 0.3)
- Glow effects: box-shadow: 0 0 30px rgba(77, 208, 225, 0.1), inset 0 1px 0 rgba(255,255,255,0.1)

## ANIMATIONS

- Soft glow pulse on active elements (opacity fade, not color shift)
- Smooth 300-500ms transitions on state changes
- Data entry fade-in + slide from top (200-300ms)
- Age-based opacity fade for log entries (full brightness → 50% over 30s)
- Message flow on graph edges: subtle animated line (slow, dreamy)
- Progress bars: smooth fill transition

## LAYOUT

Main dashboard grid (responsive):
```
┌─────────────────────────────────────┐
│ Swarm Status | Topology Graph       │ Agent Roster
├─────────────────────────────────────┤
│ Memory Browser | Security Monitor   │
├─────────────────────────────────────┤
│ Task Orchestrator | Event Log       │
└─────────────────────────────────────┘
```

Gutters: 20-24px, generous padding everywhere.

## SUCCESS CRITERIA

✓ Dashboard displays all 8 components
✓ Mock data streams in real-time (30-40 events per session)
✓ All panels update smoothly without lag or jarring flashes
✓ Animations are subtle and dreamy (not harsh or overdone)
✓ Color palette is consistent across all components
✓ Works on desktop and tablet (responsive grid)
✓ Can connect to live backend via WebSocket URL in .env
✓ Accessibility: good contrast, readable fonts, focus states

## DELIVERABLES

- Fully functional React app (ready to npm install && npm run dev)
- All components in /src/components
- Mock data generator + WebSocket hook in /src/hooks and /src/utils
- Tailwind config with custom design tokens
- CSS files for globals, theme, component-specific styles
- .env.example with configuration
- README.md with setup & usage instructions
```

---

## Additional Notes for Claude Code

### Environment Variables (`.env.example`)
```
# WebSocket backend URL (leave empty to use mock data)
REACT_APP_WS_URL=ws://localhost:8000/ws

# Force use of mock data (true/false)
REACT_APP_USE_MOCK_DATA=true

# Mock data delay interval (ms) — space out events
REACT_APP_MOCK_EVENT_INTERVAL=500
```

### Dependencies to Install
```bash
npm install react react-dom
npm install -D tailwindcss postcss autoprefixer
npm install recharts
npm install reactflow
npm install lucide-react
npm install zustand  # optional, for state management
```

### Key Design Decisions
1. **No harsh reds/greens** — using soft magenta and pale cyan instead
2. **Pulsing opacity, not color shifts** — more ethereal, less jarring
3. **Generous whitespace** — breathing room over information density
4. **Mock data by default** — dashboard works immediately without backend setup
5. **Glassmorphic panels** — frosted glass effect with blur, not flat colors

### Testing the Dashboard
1. Start with mock data enabled
2. Verify all components render correctly
3. Check animations at normal speed (not too fast/slow)
4. Test responsive resize (should adapt gracefully)
5. Once happy with styling, test real WebSocket connection (if available)

---

## References & Inspiration

- **Board:** Your A3RO Pinterest collection (ethereal, holographic, luminous)
- **UI Patterns:** Blade Runner 2049 aesthetic, command centers, hacker dashboards
- **Color Psychology:** Cool, calm, trustworthy (not aggressive)
- **Animation Philosophy:** Subtle, dreamy, non-intrusive

---

**Good luck! You're building something beautiful.** 🌌

