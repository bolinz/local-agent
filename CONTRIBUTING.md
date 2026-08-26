# Contributing to LocalMind

Thank you for your interest in contributing to LocalMind!

## Development Setup

1. Clone the repo
2. `cd LocalMind && xcodegen generate`
3. Open `LocalMind.xcodeproj` in Xcode, or build from command line

## Code Standards

- **Swift 5.9+**, **iOS 17+** deployment target
- Follow existing patterns — check existing code before adding new files
- All new features must include unit tests (`swift test`)
- UI changes must pass UI tests (`./run-uitests.sh`)

## Branching

- `main` branch is protected — all changes must go through PRs
- Create feature branches: `feature/<name>` or `fix/<name>`
- PRs require passing CI (unit tests + UI tests)

## Testing

```bash
# Unit tests (required for all changes)
cd LocalMind && swift test

# UI tests (required for UI changes)
cd LocalMind && ./run-uitests.sh
```

## Architecture

- **Tool Protocol** — add new tools by conforming to `Tool` protocol
- **Workflow Engine** — structured automations with JSON persistence
- **Views** — SwiftUI, iOS 17+, follow existing component patterns

## Pull Request Checklist

- [ ] Unit tests pass (`swift test`)
- [ ] UI tests pass (`./run-uitests.sh`)
- [ ] No new compiler warnings
- [ ] Code follows existing patterns
- [ ] Commit messages are descriptive
