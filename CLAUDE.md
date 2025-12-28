# Context Capture

A canvas for your working memory. Drop screenshots, get AI-generated context automatically.

## Quick Start

```bash
# 1. Start the Brain (for semantic search)
cd brain && swift build -c release
.build/release/ContextCaptureBrain serve

# 2. Open the frontend
open index.html
```

## What It Does

1. **Drop** — Drag screenshots onto the canvas (or paste with ⌘V)
2. **Analyze** — Claude vision automatically describes what's in each image
3. **Persist** — Cards and positions save to localStorage + Brain
4. **Search** — Semantic search using Apple NLContextualEmbedding
5. **Resume** — Come back tomorrow with full context

## Architecture

```
┌──────────────────────────────────────┐
│       Context Capture (HTML)         │
│     Drop screenshots, get context    │
└──────────────────┬───────────────────┘
                   │ HTTP (localhost:8770)
                   ▼
┌──────────────────────────────────────┐
│     Context Capture Brain (Swift)    │
│  NLContextualEmbedding + SQLite      │
└──────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│   ~/.context-capture/brain.db        │
│   (syncs via iCloud/Dropbox/Git)     │
└──────────────────────────────────────┘
```

## Brain (Local Vector Store)

The Brain provides semantic search using Apple's on-device ML:

```bash
# Build
cd brain && swift build -c release

# Start server (port 8770)
.build/release/ContextCaptureBrain serve

# Test embedding
.build/release/ContextCaptureBrain embed "TypeScript error"

# CLI search
.build/release/ContextCaptureBrain search "authentication bug" --limit 5
```

**Why local?**
- Free — No API costs for embeddings
- Private — Data never leaves your machine
- Fast — On-device inference with Apple Silicon
- Offline — Works without internet

## Tech Stack

- React 18 (CDN)
- Claude API (vision for captioning)
- Apple NLContextualEmbedding (embeddings)
- SQLite (vector storage)
- Hummingbird (Swift HTTP server)
- Single HTML file

## API Key

First use prompts for Anthropic API key. Stored in localStorage. BYOK model.

## Design System

- **Background:** #09090B
- **Accent:** #f59e0b (amber)
- **Font:** Roboto / Roboto Mono
- Dark mode only

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | Add new screenshot |
| ⌘/ | Focus search |
| ⌘V | Paste screenshot |
| ESC | Clear search / close modal |
| Double-click card | Expand card fullscreen |
| Space + drag | Pan canvas |
| Scroll wheel | Zoom in/out |
| Double-click canvas | Reset view |
| 0 or Home | Reset view |

## Canvas Navigation

The canvas supports Figma-style navigation:
- **Pan:** Hold Space + drag (cursor changes to grab hand)
- **Zoom:** Scroll wheel (zooms centered on cursor)
- **Reset:** Double-click empty canvas, or press 0/Home

## v0 Scope (Jobs-Mode Approved)

| Feature | Status |
|---------|--------|
| Canvas with drag-drop | ✅ |
| Cards (image + caption) | ✅ |
| AI vision on drop | ✅ |
| localStorage persistence | ✅ |
| Fixed viewport | ✅ |
| Dark mode | ✅ |
| Semantic search (Brain) | ✅ |

## Multi-Mac Sync

The SQLite database at `~/.context-capture/brain.db` can be synced:

1. **iCloud** — Symlink to iCloud Drive
2. **Dropbox** — Put in Dropbox folder
3. **Git** — Commit the db (small enough)

Each Mac runs its own Brain server, all reading from the same synced database.

## Origin

Built from Jobs-Mode framework output. See `projects/jobs-mode/outputs/dev-log/` for full product definition.
