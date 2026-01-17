# MiniSim - Agent Guidelines

MiniSim is a macOS menu bar utility for launching iOS simulators and Android emulators. Written in Swift and AppKit.

## Build Commands

```bash
# Build the project
xcodebuild -scheme MiniSim -configuration Debug build

# Build for release
xcodebuild -scheme MiniSim -configuration Release build

# Clean build
xcodebuild -scheme MiniSim clean build
```

## Testing

```bash
# Run all tests
xcodebuild test -scheme MiniSim -destination 'platform=macOS'

# Run a single test file
xcodebuild test -scheme MiniSim -destination 'platform=macOS' \
  -only-testing:MiniSimTests/DeviceParserTests

# Run a single test method
xcodebuild test -scheme MiniSim -destination 'platform=macOS' \
  -only-testing:MiniSimTests/DeviceParserTests/testIOSSimulatorParser
```

## Linting

SwiftLint is integrated via SPM. Config in `.swiftlint.yml`.

```bash
# Run SwiftLint
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Project Structure

```
MiniSim/
├── Model/           # Data models (Device, Command, Platform, etc.)
├── Service/         # Business logic and services
│   ├── CustomErrors/   # Custom error types
│   └── Terminal/       # Terminal integration
├── Views/           # SwiftUI views
│   ├── Onboarding/     # Onboarding flow
│   ├── CustomCommands/ # Custom commands UI
│   └── ParametersTable/ # Parameters management
├── Extensions/      # Swift extensions
├── MenuItems/       # NSMenu item implementations
├── Components/      # Reusable UI components
└── AppleScript Commands/ # AppleScript integration
```

## Code Style Guidelines

### Imports
- Sort imports alphabetically (enforced by SwiftLint `sorted_imports`)
- Group Foundation/AppKit imports first, then third-party

```swift
import AppKit
import Foundation
import UserNotifications
```

### Naming Conventions
- Types: `PascalCase` (e.g., `DeviceService`, `ActionFactory`)
- Variables/functions: `camelCase`
- Enums: `PascalCase` for type, `camelCase` for cases
- Protocols: Suffix with `Protocol` for dependency injection (e.g., `ShellProtocol`, `ADBProtocol`)
- `id` and `ID` are allowed as identifier names

### Types and Protocols
- Use protocols for dependency injection and testability
- Prefer `struct` for data models, `class` for services with state
- Use `final class` when inheritance is not needed

```swift
protocol DeviceServiceCommon {
  var shell: ShellProtocol { get set }
  var device: Device { get }
  func deleteDevice() throws
}

struct Device: Hashable, Codable {
  var name: String
  var identifier: String?
  var booted: Bool
}
```

### Error Handling
- Define custom errors as enums conforming to `Error` and `LocalizedError`
- Group related errors in `Service/CustomErrors/`
- Provide meaningful `errorDescription` for user-facing messages

```swift
enum DeviceError: Error, Equatable {
  case deviceNotFound
  case xcodeError
  case unexpected(code: Int)
}

extension DeviceError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .deviceNotFound:
      return NSLocalizedString("Selected device was not found...", comment: "")
    }
  }
}
```

### SwiftUI Views
- Use MVVM pattern with nested `ViewModel` class
- ViewModels extend from view type (e.g., `CustomCommands.ViewModel`)
- Use `@Published` for observable state

```swift
extension CustomCommands {
  class ViewModel: ObservableObject {
    @Published var commands: [Command] = []
    @Published var showForm = false
  }
}
```

### Extensions
- File naming: `TypeName+Feature.swift` (e.g., `UserDefaults+Configuration.swift`)
- One extension purpose per file

### Factory Pattern
- Use factory classes for creating platform-specific implementations
- Follow `ActionFactory` pattern for iOS/Android differentiation

```swift
class AndroidActionFactory: ActionFactory {
  static func createAction(for tag: SubMenuItems.Tags, ...) -> any Action {
    switch tag {
    case .copyName: return CopyNameAction(device: device)
    }
  }
}
```

### Testing
- Test files mirror source structure in `MiniSimTests/`
- Use `@testable import MiniSim`
- Create stub/mock classes for dependencies (see `Mocks/ShellStub.swift`)
- Override class methods in nested test classes for mocking

```swift
class ADBTests: XCTestCase {
  var shellStub: ShellStub!

  override func setUp() {
    shellStub = ShellStub()
    ADB.shell = shellStub
  }
}
```

### SwiftLint Rules (Key Enabled)
- `sorted_imports` - alphabetical import ordering
- `implicit_return` - omit return in single-expression closures
- `trailing_closure` - use trailing closure syntax
- `vertical_whitespace_closing_braces` - no blank lines before closing braces
- `shorthand_optional_binding` - use `if let x` instead of `if let x = x`
- `weak_delegate` - delegates should be weak

### Disabled Rules
- `nesting` - nested types are allowed

### Documentation
- Add JSDoc-style comments for new public functions
- Focus on "why" not "what" for complex logic
- No comments in JSX/SwiftUI describing what renders

### Threading
- Use `Thread.assertBackgroundThread()` for background-only operations
- Main thread assertions available via `Thread+Asserts.swift`

## Dependencies (SPM)
- `KeyboardShortcuts` - Global keyboard shortcuts
- `LaunchAtLogin` - Login item management
- `Sparkle` - Auto-updates
- `ShellOut` - Shell command execution
- `CodeEditor` - Code editing in preferences
- `SymbolPicker` - SF Symbol picker
- `Settings` - Preferences window
- `AcknowList` - Acknowledgements
- `SwiftLint` - Linting (build plugin)
