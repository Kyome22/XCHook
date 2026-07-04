import Foundation
import Testing
@testable import XCHook

private func makeTemporaryDirectory() throws -> URL {
    let directoryURL = FileManager.default.temporaryDirectory
        .appending(path: "XCHookTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
}

private func makeBehaviors(xchookPath: String) -> RunScriptBehaviors {
    RunScriptBehaviors(
        runScriptsDirectoryURL: XCHookDirectory(baseURL: URL(filePath: xchookPath)).runScriptsDirectoryURL
    )
}

struct RunScriptBehaviorsTests {
    @Test
    func registerAddsRunScriptsForAllEvents() {
        let behaviors = makeBehaviors(xchookPath: "/Users/foo/.xchook")
        let registered = behaviors.register(into: [:])
        #expect(behaviors.isRegistered(in: registered))
    }

    @Test
    func registerPreservesUnrelatedAlertSettings() throws {
        let behaviors = makeBehaviors(xchookPath: "/Users/foo/.xchook")
        let original: [String: Any] = [
            "Xcode.AlertEvent.BuildStart": [
                "Xcode.Alert.Sound": ["enabled": 1, "name": "Submarine"],
                "Xcode.Alert.RunScript": ["enabled": 0, "path": ""]
            ]
        ]
        let registered = behaviors.register(into: original)
        let buildStart = try #require(registered["Xcode.AlertEvent.BuildStart"] as? [String: Any])
        let sound = try #require(buildStart["Xcode.Alert.Sound"] as? [String: Any])
        #expect(sound["name"] as? String == "Submarine")
        let runScript = try #require(buildStart["Xcode.Alert.RunScript"] as? [String: Any])
        #expect(runScript["path"] as? String == "/Users/foo/.xchook/run_scripts/build_start.sh")
    }

    @Test
    func unregisterDisablesRunScriptsForAllEvents() throws {
        let behaviors = makeBehaviors(xchookPath: "/Users/foo/.xchook")
        let unregistered = behaviors.unregister(from: behaviors.register(into: [:]))
        #expect(!behaviors.isRegistered(in: unregistered))
        let buildStart = try #require(unregistered["Xcode.AlertEvent.BuildStart"] as? [String: Any])
        let runScript = try #require(buildStart["Xcode.Alert.RunScript"] as? [String: Any])
        #expect(runScript["enabled"] as? Int == 0)
        #expect(runScript["path"] as? String == "")
    }

    @Test
    func isRegisteredDetectsPathMismatch() {
        let registered = makeBehaviors(xchookPath: "/Users/foo/.xchook").register(into: [:])
        #expect(!makeBehaviors(xchookPath: "/Users/bar/.xchook").isRegistered(in: registered))
    }
}

struct XCHookFileTests {
    @Test
    func copyRunScriptsInstallsAllExecutableScripts() throws {
        let temporaryDirectoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectoryURL) }
        let xchook = XCHook(directory: XCHookDirectory(baseURL: temporaryDirectoryURL.appending(path: ".xchook")))

        try xchook.createXCHookDirectories()
        try xchook.copyRunScripts()

        let scriptNames = try FileManager.default
            .contentsOfDirectory(atPath: xchook.directory.runScriptsDirectoryURL.path)
            .sorted()
        #expect(scriptNames == [
            "build_fails.sh",
            "build_start.sh",
            "build_succeeds.sh",
            "post_event.sh",
            "testing_fails.sh",
            "testing_start.sh",
            "testing_succeeds.sh"
        ])
        for scriptName in scriptNames {
            let scriptPath = xchook.directory.runScriptsDirectoryURL.appending(path: scriptName).path
            #expect(FileManager.default.isExecutableFile(atPath: scriptPath))
        }

        try xchook.removeXCHookDirectory()
        #expect(!FileManager.default.fileExists(atPath: xchook.directory.baseURL.path))
    }
}

struct RunScriptTests {
    private func runScript(
        named scriptName: String,
        homeDirectoryURL: URL,
        environment: [String: String]
    ) throws {
        let xchook = XCHook(directory: XCHookDirectory(baseURL: homeDirectoryURL.appending(path: ".xchook")))
        try xchook.createXCHookDirectories()
        try xchook.copyRunScripts()

        let process = Process()
        process.executableURL = xchook.directory.runScriptsDirectoryURL.appending(path: scriptName)
        process.environment = environment.merging(["HOME": homeDirectoryURL.path]) { _, new in new }
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }

    private func writtenEvents(homeDirectoryURL: URL) throws -> [XCHookEvent] {
        let eventsDirectoryURL = homeDirectoryURL.appending(path: ".xchook/events")
        var events = [XCHookEvent]()
        for fileName in try FileManager.default.contentsOfDirectory(atPath: eventsDirectoryURL.path).sorted()
        where fileName.hasSuffix(".json") {
            let data = try Data(contentsOf: eventsDirectoryURL.appending(path: fileName))
            let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            let rawStatus = try #require(json["status"] as? String)
            events.append(
                XCHookEvent(
                    project: try #require(json["project"] as? String),
                    path: try #require(json["path"] as? String),
                    status: try #require(XCHookStatus(rawValue: rawStatus)),
                    timestamp: try #require(json["timestamp"] as? Double)
                )
            )
        }
        return events
    }

    @Test
    func buildStartScriptWritesEventForXcodeProject() throws {
        let homeDirectoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: homeDirectoryURL) }

        try runScript(
            named: "build_start.sh",
            homeDirectoryURL: homeDirectoryURL,
            environment: [
                "XcodeProject": "My \"Weird\" App.xcodeproj",
                "XcodeProjectPath": "/tmp/My \"Weird\" App.xcodeproj"
            ]
        )

        let events = try writtenEvents(homeDirectoryURL: homeDirectoryURL)
        #expect(events.count == 1)
        #expect(events.first?.project == "My \"Weird\" App")
        #expect(events.first?.path == "/tmp/My \"Weird\" App.xcodeproj")
        #expect(events.first?.status == .buildStart)
        #expect(events.first?.timestamp ?? 0 > 0)
    }

    @Test
    func testingSucceedsScriptWritesEventForSwiftPackage() throws {
        let homeDirectoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: homeDirectoryURL) }

        try runScript(
            named: "testing_succeeds.sh",
            homeDirectoryURL: homeDirectoryURL,
            environment: [
                "XcodeWorkspace": "package.xcworkspace",
                "XcodeWorkspacePath": "/Users/foo/Dev/XCHook/.swiftpm/xcode/package.xcworkspace"
            ]
        )

        let events = try writtenEvents(homeDirectoryURL: homeDirectoryURL)
        #expect(events.first?.project == "XCHook")
        #expect(events.first?.status == .testingSucceeds)
    }
}

struct EventStreamTests {
    private func writeEventFile(
        to eventsDirectoryURL: URL,
        project: String,
        status: XCHookStatus,
        timestamp: Double
    ) throws {
        let json = """
        {"project":"\(project)","path":"/tmp/\(project)","status":"\(status.rawValue)","timestamp":\(timestamp)}
        """
        try FileManager.default.createDirectory(at: eventsDirectoryURL, withIntermediateDirectories: true)
        try json.data(using: .utf8)?.write(to: eventsDirectoryURL.appending(path: "\(timestamp)-test.json"))
    }

    @Test(.timeLimit(.minutes(1)))
    func eventStreamEmitsFreshEventsAndDiscardsStaleOnes() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectoryURL) }
        let eventsDirectoryURL = temporaryDirectoryURL.appending(path: "events")

        try writeEventFile(
            to: eventsDirectoryURL,
            project: "Stale",
            status: .buildFails,
            timestamp: 1.0
        )

        let stream = XCHookReceiver.eventStream(directoryURL: eventsDirectoryURL)

        try await Task.sleep(for: .milliseconds(500))
        try writeEventFile(
            to: eventsDirectoryURL,
            project: "Fresh",
            status: .buildSucceeds,
            timestamp: 2.0
        )

        for await event in stream {
            #expect(event.project == "Fresh")
            #expect(event.status == .buildSucceeds)
            #expect(event.timestamp == 2.0)
            break
        }

        let remainingFileNames = try FileManager.default
            .contentsOfDirectory(atPath: eventsDirectoryURL.path)
            .filter { $0.hasSuffix(".json") }
        #expect(remainingFileNames.isEmpty)
    }
}
