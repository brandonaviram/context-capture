# Context Capture: Stickiness Analysis

Applying the 4-rung stickiness ladder framework to Context Capture.

---

## Current Scores

| Rung | Score | Verdict |
|------|-------|---------|
| 1. Habit | 6/10 | Strong capture loop, no review loop |
| 2. Data Gravity | 4/10 | Cards persist but investment invisible |
| 3. Workflow Embedding | 2/10 | No integrations |
| 4. Multiplayer | 0/10 | Single-user only |

**Overall Stickiness: 3/10** — Great capture, no retention.

---

## Rung 1: Habit

### What's Working
- **Zero-friction capture** — Drag-drop or ⌘V, instant
- **AI auto-caption** — Value delivered in 2-3 seconds
- **Keyboard shortcuts** — ⌘N, ⌘/, Space+drag for power users
- **Spatial canvas** — Position = memory (Figma-style)

### What's Missing
- **No review ritual** — You capture but never look back
- **No daily trigger** — Nothing pulls you to open the app tomorrow
- **No streak mechanics** — No psychological cost to skipping a day
- **No notifications** — "You have 5 unreviewed captures"

### Fixes (Priority Order)
1. **Unreviewed badge** — Show count of cards captured but not clicked
2. **Daily digest email** — "3 captures from yesterday you might want to review"
3. **"Last session" indicator** — Visual separation between today and previous sessions

---

## Rung 2: Data Gravity

### What's Working
- **Cards persist** — localStorage + Brain database
- **Positions saved** — Spatial arrangement survives sessions
- **Semantic search** — Find by meaning, not keywords

### What's Missing
- **No visible investment** — Can't see "147 screenshots captured"
- **No collections/tags** — Cards are isolated islands
- **No relationships** — Can't link related captures
- **No search history** — What did I look for last week?
- **No export** — Insights trapped in the canvas

### Fixes (Priority Order)
1. **Stats in header** — "47 cards · 3 this week"
2. **Tags** — #debug #design #meeting for grouping
3. **Collections view** — Filter canvas by tag
4. **Export to markdown** — Get insights out of the tool

---

## Rung 3: Workflow Embedding

### What's Working
- **macOS clipboard integration** — ⌘V from any app
- **File drag-drop** — Works with Finder, browsers, anything

### What's Missing
- **No outbound integrations** — Can't send cards anywhere
- **No Notion sync** — Natural destination for organized knowledge
- **No Linear/GitHub** — Can't turn a screenshot into a ticket
- **No Slack sharing** — Can't send a card to a channel
- **Not a hub** — Pure endpoint, nothing routes through it

### Fixes (Priority Order)
1. **"Copy as markdown"** — Quick export for pasting anywhere
2. **Send to Notion** — Create page from card (title = caption, body = image)
3. **Send to Linear** — Turn debug screenshot into ticket
4. **Webhook support** — Generic "on capture, POST to URL"

---

## Rung 4: Multiplayer

### What's Working
- Nothing. This is a single-user local-first tool.

### What's Missing
- **No sharing** — Can't send a card link to someone
- **No team canvas** — No collaborative board
- **No comments** — Can't discuss a capture
- **No permissions** — No "view only" vs "edit" distinction

### Fixes (Future, Not Priority)
1. **Share card as image** — Generate PNG with caption overlay
2. **Share canvas link** — Read-only view of your board (requires hosting)
3. **Team workspace** — Multiple users on one canvas (requires auth, cloud sync)

---

## Recommended Roadmap

### Phase 1: Habit (Low Effort, High Impact)
- [ ] Add card count to header
- [ ] Add "unreviewed" indicator on cards
- [ ] Add stats: "Captured 12 this week"

### Phase 2: Data Gravity (Medium Effort)
- [ ] Add tagging system (#debug, #meeting, #idea)
- [ ] Add collection/filter view
- [ ] Add "Copy as markdown" action on cards

### Phase 3: Workflow (Higher Effort)
- [ ] Notion integration (create page from card)
- [ ] Export all cards to markdown file
- [ ] Webhook on capture

### Phase 4: Multiplayer (Future)
- [ ] Share card as image
- [ ] Public canvas link (read-only)

---

## The Core Problem

Context Capture has a **capture loop** but no **utilization loop**.

```
Current:  Capture → Store → ... (nothing)
Needed:   Capture → Store → Review → Act → (external systems)
```

The tool creates value but doesn't extract it. Cards sit in a void.

**Fix the review loop first.** Everything else follows.

---

*Analysis date: 2025-12-14*
*Framework: doc/research/stickiness-vs-network-effects.md*
