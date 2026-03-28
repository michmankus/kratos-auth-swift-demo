# kratos-auth-swift-demo

A headless-first Swift SDK for Ory Kratos authentication flows, with a SwiftUI example app.

## Project Structure

```
.
├── Sources/
│   ├── OryAuth/          # Core SDK — headless auth client, models, error handling
│   └── OryUI/            # Optional SwiftUI components for quick prototyping
├── Dependencies/
│   ├── OryClient/        # Generated OpenAPI Swift client (v1.22.22)
│   └── SecureStorage/    # Keychain wrapper with injectable protocol
├── ExampleApp/
│   └── OryKratosDemo/    # SwiftUI demo app (MVVM + Clean Architecture)
└── fastlane/             # Build & test automation
```

## Requirements

- Xcode 16+
- iOS 16+ / macOS 13+
- Swift 6
- Ruby (for Fastlane)

## Quick Start

### 1. Install dependencies

```bash
bundle install
```

### 2. Build & Test with Fastlane

| Command | Description |
|---|---|
| `bundle exec fastlane build_sdk` | Build OryAuth & OryUI (Swift Package) |
| `bundle exec fastlane test_sdk` | Run SDK unit tests |
| `bundle exec fastlane build_app` | Build the Example App |
| `bundle exec fastlane test_app` | Run Example App unit tests |
| `bundle exec fastlane build_all` | Build everything (SDK + App) |
| `bundle exec fastlane test_all` | Run all tests (SDK + App) |

### 3. Build without Fastlane

```bash
# SDK only
swift build
swift test

# Example App (Xcode)
open ExampleApp/OryKratosDemo/OryKratosDemo.xcodeproj
```

## SDK Integration

Add the package as a local dependency or point to the repository URL:

```swift
dependencies: [
    .package(path: "../kratos-auth-swift-demo")
]
```

Then import the modules you need:

```swift
import OryAuth  // Core SDK — required
import OryUI    // SwiftUI components — optional
```

### Minimal Usage

```swift
let config = OryConfiguration(
    serverURL: URL(string: "https://your-project.projects.oryapis.com")!
)
let client = OryAuthClient(configuration: config)

// Initialize a login flow
let flow = try await client.initLoginFlow()

// Render flow.visibleFields in your UI...

// Submit credentials
let session = try await client.submitLogin(
    flowId: flow.id,
    credentials: .password(identifier: "user@example.com", password: "s3cret")
)
```

## Architecture

### SDK (OryAuth)

- **Headless-first**: No UIKit/SwiftUI dependency. Pure Swift models and async/await API.
- **Server-driven forms**: `FlowContainer` and `FormNode` models parse Ory's UI nodes so apps render forms dynamically — never hardcoded.
- **Typed errors**: `OryError` distinguishes validation, network, flow expiry, and session errors. Each mapper conforms to a `Mapper` protocol for testability.
- **Secure token storage**: Session tokens stored in Keychain via injectable `KeychainProtocol`.
- **Swift 6 strict concurrency**: All types are `Sendable`, all APIs are async/await.

### SDK (OryUI)

- **Drop-in SwiftUI components**: `OryFormField`, `OrySubmitButton`, `OryNodeMessages`, `OryFlowForm`.
- **Native field mapping**: Each `FieldType` maps to the appropriate iOS control (SecureField, Toggle, TextField with correct keyboard type).
- **Optional**: Most apps will build custom UI. OryUI is for quick MVPs.

### Example App (OryKratosDemo)

- **MVVM** with protocol-based ViewModels and Fixture pattern for SwiftUI previews.
- **Clean Architecture**: Presentation / Domain / Data layers. Only `AuthRepositoryImpl` imports the SDK client.
- **Coordinator pattern** for navigation via FlowStacks.
- **Dynamic forms**: UI renders whatever fields the server returns.
