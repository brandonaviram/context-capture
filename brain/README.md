# Context Capture Brain

Local vector store for your dev screenshots using Apple's on-device ML.

## Features

- **Apple NLContextualEmbedding** - On-device text embeddings (free, private)
- **SQLite Vector Store** - Stores embeddings locally, syncs via iCloud/Dropbox
- **Semantic Search** - Find screenshots by meaning ("that TypeScript error")
- **HTTP API** - Works with the Context Capture HTML frontend

## Requirements

- macOS 14+ (Sonoma)
- Xcode 15+
- Apple Silicon recommended (also works on Intel)

## Build

```bash
cd brain
swift build -c release
```

Binary will be at `.build/release/ContextCaptureBrain`

## Usage

### Start Server

```bash
# Default: port 8770, database at ~/.context-capture/brain.db
./ContextCaptureBrain serve

# Custom port and database
./ContextCaptureBrain serve --port 8080 --database ~/my-brain.db
```

### Test Embedding

```bash
./ContextCaptureBrain embed "TypeScript error in auth flow"
# Output: Dimension: 512
# First 10 values: [0.023, -0.156, ...]
```

### Search (CLI)

```bash
./ContextCaptureBrain search "authentication error" --limit 5
# Results for: "authentication error"
# ---
# 1. [0.89] VS Code showing TypeScript type mismatch in auth middleware
# 2. [0.76] Terminal with npm error during login flow
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/cards` | List all cards |
| POST | `/cards` | Add a card (with auto-embedding) |
| DELETE | `/cards/{id}` | Delete a card |
| POST | `/search` | Semantic search |

### Add Card

```bash
curl -X POST http://localhost:8770/cards \
  -H "Content-Type: application/json" \
  -d '{
    "id": "abc123",
    "imagePath": "/path/to/screenshot.png",
    "caption": "VS Code showing React hook error",
    "x": 100,
    "y": 200
  }'
```

### Semantic Search

```bash
curl -X POST http://localhost:8770/search \
  -H "Content-Type: application/json" \
  -d '{"query": "react hooks", "limit": 5}'
```

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

## Multi-Mac Sync

The SQLite database at `~/.context-capture/brain.db` can be synced across machines:

1. **iCloud** - Symlink to iCloud Drive
2. **Dropbox** - Put in Dropbox folder
3. **Git** - Commit the db (small enough)

Each Mac runs its own Brain server, all reading from the same synced database.

## Why Local?

- **Free** - No API costs for embeddings
- **Private** - Data never leaves your machine
- **Fast** - On-device inference with Apple Silicon
- **Offline** - Works without internet

## Future: Foundation Models Integration

When using macOS 26+, can add Apple Intelligence for:
- Image captioning (instead of Claude API)
- Smarter context generation
- Natural language queries

Currently uses Claude API for captions, Apple NL for embeddings.
