/*
 RunScriptBehaviors.swift
 XCHook

 Created by Takuto Nakamura on 2022/04/11.
 */

import Foundation

struct RunScriptBehaviors {
    private enum AlertEvent: String, CaseIterable {
        case buildStart      = "Xcode.AlertEvent.BuildStart"
        case buildSucceeds   = "Xcode.AlertEvent.BuildSucceeds"
        case buildFails      = "Xcode.AlertEvent.BuildFails"
        case testingStart    = "Xcode.AlertEvent.TestingStart"
        case testingSucceeds = "Xcode.AlertEvent.TestingSucceeds"
        case testingFails    = "Xcode.AlertEvent.TestingFails"

        var scriptName: String {
            switch self {
            case .buildStart:      "build_start.sh"
            case .buildSucceeds:   "build_succeeds.sh"
            case .buildFails:      "build_fails.sh"
            case .testingStart:    "testing_start.sh"
            case .testingSucceeds: "testing_succeeds.sh"
            case .testingFails:    "testing_fails.sh"
            }
        }
    }

    static let legacyAlertEventsKey = "Xcode.AlertEvents"
    static let modernAlertEventsKey = "Xcode.AlertEvents.4_1"
    static let alertEventsKeys = [legacyAlertEventsKey, modernAlertEventsKey]
    static let recentScriptsKey = "Xcode.Alert.Script.Recent"

    private static let runScriptKey = "Xcode.Alert.RunScript"

    private let runScriptsDirectoryURL: URL

    init(runScriptsDirectoryURL: URL) {
        self.runScriptsDirectoryURL = runScriptsDirectoryURL
    }

    var expectedScriptPaths: [String] {
        AlertEvent.allCases.map { scriptPath(for: $0) }
    }

    private func scriptPath(for alertEvent: AlertEvent) -> String {
        runScriptsDirectoryURL.appending(path: alertEvent.scriptName).path
    }

    func register(into dict: [String: Any]) -> [String: Any] {
        merge(into: dict) { alertEvent in
            ["enabled": 1, "path": scriptPath(for: alertEvent)]
        }
    }

    func unregister(from dict: [String: Any]) -> [String: Any] {
        merge(into: dict) { _ in
            ["enabled": 0, "path": ""]
        }
    }

    func isRegistered(in dict: [String: Any]) -> Bool {
        AlertEvent.allCases.allSatisfy { alertEvent in
            guard let event = dict[alertEvent.rawValue] as? [String: Any],
                  let runScript = event[Self.runScriptKey] as? [String: Any],
                  let enabled = runScript["enabled"] as? NSNumber,
                  let path = runScript["path"] as? String else {
                return false
            }
            return enabled.boolValue && path == scriptPath(for: alertEvent)
        }
    }

    private func merge(
        into dict: [String: Any],
        runScript: (AlertEvent) -> [String: Any]
    ) -> [String: Any] {
        var merged = dict
        for alertEvent in AlertEvent.allCases {
            var event = merged[alertEvent.rawValue] as? [String: Any] ?? [:]
            var existingRunScript = event[Self.runScriptKey] as? [String: Any] ?? [:]
            existingRunScript.merge(runScript(alertEvent)) { _, new in new }
            event[Self.runScriptKey] = existingRunScript
            merged[alertEvent.rawValue] = event
        }
        return merged
    }
}
