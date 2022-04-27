# XCHook

Hooking the events (building and testing) of Xcode.app.


## Usage

**Install XCHook to your project via Swift Package Manager**

Add Swift Package: `https://github.com/Kyome22/XCHook.git`

**Install scripts of XCHook to Xcode.app**

**Receive XCHookEvent**

```swift
import Cocoa
import Combine
import XCHook

class ViewController: NSViewController {
    @IBOutlet weak var projectLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!

    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        XCHookReceiver.shared.xchookPublisher
            .sink { [weak self] event in
                self?.projectLabel.stringValue = "Project: \(event.project)"
                self?.statusLabel.stringValue = "Status: \(event.status.rawValue)"
            }
            .store(in: &cancellables)
    }
}
```
