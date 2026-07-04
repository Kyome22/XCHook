/*
 XcodeApplication.swift
 XCHook

 Created by Takuto Nakamura on 2026/07/04.
 */

import AppKit

public enum XcodeApplication {
    static let bundleIdentifier = "com.apple.dt.Xcode"

    public static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    @discardableResult
    public static func restart(timeout: Duration = .seconds(30)) async -> Bool {
        guard let runningXcode = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first,
              let bundleURL = runningXcode.bundleURL else {
            return false
        }
        runningXcode.terminate()
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while isRunning {
            guard ContinuousClock.now < deadline else {
                return false
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
        do {
            try await NSWorkspace.shared.openApplication(at: bundleURL, configuration: .init())
            return true
        } catch {
            return false
        }
    }
}
