# XCHook

Hooking the events (building and testing) of Xcode.app.

## Usage

**Install XCHook to your project via Swift Package Manager**

Add Swift Package: `https://github.com/Kyome22/XCHook.git`

**Install scripts of XCHook to Xcode.app**

```swift
import XCHook

if let xchook = XCHook() {
    xchook.install()
} else {
    print("Failed to initialize XCHook; Xcode.plist does not found.")
}
```

**Receive XCHookEvent**

```swift
import Combine
import XCHook

var cancellables = Set<AnyCancellable>()

XCHookReceiver.shared.xchookPublisher
    .sink { event in
        Swift.print("Project: \(event.project)")
        Swift.print("Project path: \(event.path)")
        Swift.print("Status: \(event.status.rawValue)")
    }
    .store(in: &cancellables)
```

**Uninstall scripts of XCHook from Xcode.app**

```swift
import XCHook

if let xchook = XCHook() {
    xchook.uninstall()
} else {
    print("Failed to initialize XCHook; Xcode.plist does not found.")
}
```
