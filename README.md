# kratos-auth-swift-demo

A headless-first Swift SDK for Ory Kratos authentication flows, with a SwiftUI example app.

## Demo

https://github.com/user-attachments/assets/7e05f36f-356c-4969-865d-98cb0d372bdd


## Project Structure

```
.
├── Sources/
│   ├── OryAuth/          # Core SDK - headless auth client, models, error handling
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
- Ruby 3.1.2 (for Fastlane)

## Quick Start [XCode]

### Demo App

Open the `ExampleApp/OryKratosDemo/OryKratosDemo.xcodeproj` file with Xcode 16+. This should open a demo app and load Swift Package dependencies. Run the app in simulator by using CMD + R or just click it at the top navigation bar.
NOTE: You can't have SDK project open in Xcode and ExampleApp at the same time, it will cause issues with loading dependencies.

You can also run in the console `open ExampleApp/OryKratosDemo/OryKratosDemo.xcodeproj`

**NOTE: Don't open Demo App & SDK Package at the same time, it will cause Xcode to have issues with resolving package dependencies and errors.**

### SDK

Open the XCode, then click File > Open > root folder of the repository > Click Open. This should open the SDK Swift Package itself in XCode and load dependencies.

If you have xcode tools installed, you can also run in the console `xed .`

## Quick Start [Console]

You don't need to do any of this, for checking out the Demo App and SDK the steps above in XCode are enought. Console commands are built for CI & CD purpose, they require to run on the same environment as the dev team (macOS, XCode version, simulators, Ruby version).

### 1. Install dependencies

```bash
bundle install
```

### 2. Build & Test with Fastlane

| Command | Description |
|---|---|
| `bundle exec fastlane build_sdk` | Build OryAuth & OryUI (Swift Package) |
| `bundle exec fastlane test_sdk` | Run SDK unit tests |
| `bundle exec fastlane build_example_app` | Build the Example App |
| `bundle exec fastlane test_example_app` | Run Example App unit tests |
| `bundle exec fastlane build_all` | Build everything (SDK + App) |
| `bundle exec fastlane test_all` | Run all tests (SDK + App) |
| `bundle exec fastlane coverage_sdk` | Run SDK tests with code coverage report |

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
import OryAuth  // Core SDK - required
import OryUI    // SwiftUI components - optional
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

### SDK Boundaries

The SDK is split into three layers. Each one only talks to the layer below it.

```
┌─────────────────────────────────────────────┐
│  Your App / ExampleApp                      │
│  imports: OryAuth, OryUI (optional)         │
├─────────────────────────────────────────────┤
│  OryAuth  (public API)                      │
│  OryAuthClient, FlowContainer, FormNode,    │
│  OryError, OrySession, LoginCredentials     │
├─────────────────────────────────────────────┤
│  OryClient  (generated, never exposed)      │
│  SecureStorage  (Keychain, injectable)       │
└─────────────────────────────────────────────┘
```

- **OryAuth** is the public SDK. It exposes only clean Swift types. The generated `OryClient` types never leak out - consumers never import `OryClient` directly.
- **OryUI** is an optional SwiftUI module. It provides ready-to-use form components (`OryFormField`, `OrySubmitButton`, `OryFlowForm`) built on top of OryAuth models. Most apps will write their own UI - OryUI is there for quick MVPs.
- **OryClient** is the raw OpenAPI-generated client. It lives in `Dependencies/` and is an internal detail of OryAuth.
- **SecureStorage** wraps the iOS Keychain behind a `KeychainProtocol`. You can inject a mock for tests.

### State Management

There's no global state in the SDK. Each method call is a standalone request.

- **Flows are short-lived.** You call `initLoginFlow()`, get a `FlowContainer`, render it, then submit. The SDK doesn't hold on to it.
- **Session tokens** are the only persisted state. They go straight to the Keychain via `TokenStorage`. The SDK reads/writes them as needed - no in-memory cache.
- **The Example App** manages its own state. `AuthRepositoryImpl` (an actor) caches the current `OrySession` and exposes it to ViewModels. ViewModels are `@MainActor` and own their UI state (`flow`, `fieldValues`, `isLoading`, `errorMessage`). Navigation lives in a Coordinator, separate from business logic.

### Error Model

Every SDK method throws `OryError`. It's an enum with a case for each thing that can go wrong:

```swift
public enum OryError: Error, Sendable {
    case network(underlying: Error)       // no connectivity, timeout, DNS
    case validation(flow: FlowContainer)  // 400 - form has field-level errors
    case flowExpired(newFlowId: String?)  // 410 - flow timed out, start over
    case sessionAlreadyAvailable          // 400 - user is already logged in
    case unauthorized                     // 401 - token expired or invalid
    case missingSessionToken              // server didn't return a token
    case keychainError(Error)             // Keychain read/write failed
    case unknown(statusCode: Int, message: String?)
}
```

The key case is `.validation(flow:)` - it carries an updated `FlowContainer` with per-field error messages. Your UI just swaps the old flow for the new one and the errors show up next to the right fields. No manual parsing needed.

Error mapping is done by three small mappers, each conforming to a `Mapper` protocol:

- `OryErrorMapper` - routes `any Error` to the right case (URLError, ErrorResponse, etc.)
- `ValidationErrorMapper` - decodes HTTP 400 bodies into `.validation` or `.sessionAlreadyAvailable`
- `FlowExpiredErrorMapper` - decodes HTTP 410 bodies into `.flowExpired`

All mappers use `Failure = Never`, so you call them with `.flatMap()` and always get a result.

## If I Had 2 More Days

### Registration Flow

The SDK already supports `initRegistrationFlow()` and `submitRegistration()`. The Example App has a working registration screen. What's missing is the full post-registration experience - email verification polling, "check your inbox" screen, and the re-login redirect after verification completes. I'd also add recovery and verification flows to the SDK (`initRecoveryFlow`, `submitRecovery`, etc.) since they follow the same init -> render -> submit pattern.

### Theming & UI Customization

OryUI ships functional components but no theming system. I'd add SwiftUI view modifiers so you can customize colors, fonts, and spacing without forking the code. Something like `.oryFormStyle(theme:)` that cascades down to all OryUI components via environment values.

That said - in every production project I've worked on over the past decade, teams build their own UI with their own design system. Nobody uses SDK-provided components beyond a quick MVP. So theming is a nice-to-have, not a blocker. The real value is in OryAuth's headless API, which gives you full control.

### Additional Node & Method Coverage

The SDK currently handles `input` node types. I'd add support for `text` nodes (TOTP secret display), `image` nodes (QR codes), and `anchor` nodes (links). On the method side, I'd cover `code` (OTP via email/SMS) and `passkey` (WebAuthn) - the credential enums are already designed for extension. Passkeys need `ASAuthorizationPlatformPublicKeyCredentialProvider` and Associated Domains, which I'd implement but demo with password since passkeys require server-side domain configuration.

### What Else I'd Improve

**Testing infrastructure.** Add `StubFactory` types that make it trivial to create test fixtures for `FlowContainer`, `FormNode`, `OrySession`, etc. Right now previews and tests build their own stubs - a shared factory in the SDK would save everyone time.

**UIKit Example App.** I focused on SwiftUI for time reasons. I'd add a parallel UIKit example to show that the SDK works just as well without SwiftUI - it's headless, after all. The same `OryAuthClient` and `AuthRepository` pattern works with UIKit ViewControllers and delegates.

**Full pre-built screens.** OryUI currently provides form-level components. I'd consider shipping complete screens (login, registration, profile) that work out of the box with zero integration. The trade-off is real though - production apps almost always build custom flows with their own navigation and design system. Pre-built screens help juniors and MVPs, but experienced teams won't use them.

**Configurable Keychain storage.** `TokenStorage` currently hardcodes `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. I'd make `kSecAttrAccessible` and `kSecAttrSynchronizable` configurable via `OryConfiguration`, so developers can choose their security level or sync tokens across devices via iCloud Keychain.

**Multi-platform support.** The SDK already builds for macOS. I'd add tvOS support - it should be straightforward since OryAuth has no UI dependencies. OryUI would need separate packages per platform (tvOS focus-based UI is fundamentally different from iOS touch).

**Localization.** OryUI currently uses server-provided labels and messages as-is. I'd add a localization layer so developers can override messages, button titles, and error strings. But again - teams with custom UI handle localization themselves, so this mainly benefits the pre-built components path.

**Changelog automation.** The repo uses conventional commits (`feat:`, `chore:`, `fix:`). I'd add a script (or Fastlane lane) that generates a changelog from the commit history, grouped by type. Makes releases easier to document.

**SecureEnclaveKeyStorage** I would consider implementing a new utility class for securely managing cryptographic keys using Apple's Secure Enclave. It would porvide methods to generate, retrieve, delete and check the existence of keys, ensuring that private keys never leave the device's secure environment (lookup how secure enclave works on Apple Hardware). This would enhance security for cryptographic operations sunc as signing and encryption.