# LocalMind Agent OS

An open-source, free AI Agent running on your iPhone — create automations with natural language, your data stays on your device.

## What is it?

LocalMind is a local-first AI assistant that can **act**, not just chat. It understands your intent, calls system tools (calendar, reminders, notifications), and creates persistent automations — all without sending data to the cloud.

## Features

- **Natural language to action** — say what you want, Agent does it
- **Multi-agent management** — create and switch between different AI agents with unique personas
- **Workflow engine** — persistent automations with cron triggers and tool pipelines
- **System tools** — calendar, reminders, notifications, health data (MVP)
- **Streaming responses** — characters revealed progressively as the AI generates
- **File & image attachments** — send photos and documents from your device
- **Model switching** — local models + external API providers (OpenAI, Anthropic, DeepSeek)
- **Siri Shortcuts** — "用 LocalMind 创建提醒" / "问 LocalMind ..."
- **iPad split view** — adaptive sidebar navigation on iPad
- **100% local-first** — all processing on device, cloud only with your API key

## Architecture

```
Chat Runtime (Agent Instance)
├── Agent Config    system prompt / tools / preferences / data policy
└── Skill Pack      metadata + instructions + required tools
      └── Tool System   Tool protocol + ToolRegistry
            ├── CalendarTool / ReminderTool / NotificationTool
            ├── WorkflowTool (create/modify/toggle workflows)
            └── [extensible: HealthKit, HomeKit, Location...]
```

- **Chat is the only entry point** — natural language → intent → tool call
- **Workflow engine** — structured models (trigger/steps/logs) + JSON persistence

## Getting Started

### Requirements

- macOS with Xcode 16+ (iOS 17+ deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build & Run

```bash
cd LocalMind

# Generate Xcode project
xcodegen generate

# Build for iOS Simulator
xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build build

# Or build for real device (requires Apple Developer account)
xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
  -destination 'platform=iOS,id=<device-udid>' \
  -allowProvisioningUpdates -derivedDataPath build-device build
```

### Tests

```bash
cd LocalMind
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Unit tests (77 tests, fast)
swift test

# UI tests (use run-uitests.sh to avoid Xcode 26 hang bug)
./run-uitests.sh
./run-uitests.sh testChatSendsMessageAndGetsReply   # single test
./run-uitests.sh --list                              # list all tests
```

**⚠️ Do not run `xcodebuild test` directly** — it hangs indefinitely on Xcode 26.5 due to a backboardd crash. Use `run-uitests.sh` which runs on iOS 26.4 runtime.

## Project Structure

```
LocalMind/
├── Package.swift              # SwiftPM: lib + unit tests
├── project.yml                # XcodeGen: iOS/macOS targets + UI tests
├── run-uitests.sh             # UI test runner (iOS 26.4, timeout protection)
├── Sources/
│   ├── Agent/                 # Tool protocol, ToolRegistry, intents, 4 tools
│   ├── Models/                # ChatMessage, Workflow, AgentProfile, etc.
│   ├── Services/              # ChatService, WorkflowEngine, StorageService
│   └── Views/                 # SwiftUI views (chat, workflows, settings)
├── Tests/                     # Unit tests (77 tests)
└── UITests/                   # UI tests (6 tests, XCUITest)
docs/                          # Design specs, test plans, diagnostics
```

## Tech Stack

| Component | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM + Tool Protocol |
| Persistence | UserDefaults (JSON) + Sandbox files |
| Build | XcodeGen + SwiftPM |
| Testing | XCTest + XCUITest |
| Model integration | MiMo V2.5 (vision), local models via MLX |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

## Acknowledgments

Built with SwiftUI, App Intents, and the vision of a privacy-first AI assistant.
