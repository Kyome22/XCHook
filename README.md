# XCHook

Hooking the events (building and testing) of Xcode.app.

XCHook registers run scripts to Xcode's Behaviors preferences.
When Xcode builds or tests a project, the scripts drop event files into `~/.xchook/events/`, and `XCHookReceiver` delivers them to your app as an `AsyncSequence`.

## Requirements

- macOS 15+
- No sandbox (XCHook writes to Xcode's preferences)

## Usage

**Install XCHook to your project via Swift Package Manager**

Add Swift Package: `https://github.com/Kyome22/XCHook.git`

**Install scripts of XCHook to Xcode.app**

```swift
import XCHook

if let xchook = XCHook() {
    try xchook.install()
} else {
    print("Failed to initialize XCHook; Xcode.plist does not found.")
}
```

Xcode loads the Behaviors preferences at launch, so Xcode must be relaunched after the installation.
You can offer a one-click relaunch:

```swift
import XCHook

if XcodeApplication.isRunning {
    await XcodeApplication.restart()
}
```

**Receive XCHookEvent**

```swift
import XCHook

for await event in XCHookReceiver.events {
    print("Project: \(event.project)")
    print("Project path: \(event.path)")
    print("Status: \(event.status.rawValue)")
}
```

`XCHookReceiver.events` is a shared `AsyncSequence`, so multiple tasks can iterate it concurrently.

**Uninstall scripts of XCHook from Xcode.app**

```swift
import XCHook

if let xchook = XCHook() {
    try xchook.uninstall()
} else {
    print("Failed to initialize XCHook; Xcode.plist does not found.")
}
```
