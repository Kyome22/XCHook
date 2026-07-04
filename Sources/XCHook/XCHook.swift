/*
 XCHook.swift
 XCHook

 Created by Takuto Nakamura on 2022/04/27.
 */

import Foundation

public struct XCHook: Sendable {
    public enum Error: Swift.Error {
        case runScriptsResourceNotFound
        case copyRunScriptsFailed
        case synchronizePreferencesFailed
    }

    let directory: XCHookDirectory

    private var behaviors: RunScriptBehaviors {
        RunScriptBehaviors(runScriptsDirectoryURL: directory.runScriptsDirectoryURL)
    }

    public init?() {
        let xcodePreferencesURL = FileManager.homeDirectoryURL
            .appending(path: "Library/Preferences/\(XcodeApplication.bundleIdentifier).plist")
        guard FileManager.default.fileExists(atPath: xcodePreferencesURL.path) else { return nil }
        directory = .default
    }

    init(directory: XCHookDirectory) {
        self.directory = directory
    }

    public func isInstalled() -> Bool {
        guard behaviors.expectedScriptPaths.allSatisfy(FileManager.default.fileExists(atPath:)),
              let alertEvents = copyPreferenceValue(forKey: RunScriptBehaviors.modernAlertEventsKey) else {
            return false
        }
        return behaviors.isRegistered(in: alertEvents)
    }

    public func install() throws {
        try createXCHookDirectories()
        try copyRunScripts()
        try registerBehaviors()
    }

    public func uninstall() throws {
        try unregisterBehaviors()
        try removeXCHookDirectory()
    }

    func createXCHookDirectories() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory.runScriptsDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: directory.eventsDirectoryURL, withIntermediateDirectories: true)
    }

    func removeXCHookDirectory() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: directory.baseURL.path) {
            try fileManager.removeItem(at: directory.baseURL)
        }
    }

    func copyRunScripts() throws {
        guard let bundledRunScriptsURL = Bundle.module.url(forResource: "run_scripts", withExtension: nil) else {
            throw Error.runScriptsResourceNotFound
        }
        let fileManager = FileManager.default
        let scriptNames = try fileManager.contentsOfDirectory(atPath: bundledRunScriptsURL.path)
        for scriptName in scriptNames where scriptName.hasSuffix(".sh") {
            let sourceURL = bundledRunScriptsURL.appending(path: scriptName)
            let destinationURL = directory.runScriptsDirectoryURL.appending(path: scriptName)
            let attributes: [FileAttributeKey: Any] = [.posixPermissions: NSNumber(value: 0o755)]
            guard let scriptData = fileManager.contents(atPath: sourceURL.path),
                  fileManager.createFile(atPath: destinationURL.path, contents: scriptData, attributes: attributes) else {
                throw Error.copyRunScriptsFailed
            }
        }
    }

    func registerBehaviors() throws {
        for key in RunScriptBehaviors.alertEventsKeys {
            let currentValue = copyPreferenceValue(forKey: key) ?? [:]
            setPreferenceValue(behaviors.register(into: currentValue), forKey: key)
        }
        try synchronizePreferences()
    }

    func unregisterBehaviors() throws {
        for key in RunScriptBehaviors.alertEventsKeys {
            let currentValue = copyPreferenceValue(forKey: key) ?? [:]
            setPreferenceValue(behaviors.unregister(from: currentValue), forKey: key)
        }
        setPreferenceValue([String](), forKey: RunScriptBehaviors.recentScriptsKey)
        try synchronizePreferences()
    }

    private func copyPreferenceValue(forKey key: String) -> [String: Any]? {
        CFPreferencesCopyValue(
            key as CFString,
            XcodeApplication.bundleIdentifier as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) as? [String: Any]
    }

    private func setPreferenceValue(_ value: Any, forKey key: String) {
        CFPreferencesSetValue(
            key as CFString,
            value as CFPropertyList,
            XcodeApplication.bundleIdentifier as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }

    private func synchronizePreferences() throws {
        let succeeded = CFPreferencesSynchronize(
            XcodeApplication.bundleIdentifier as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        guard succeeded else {
            throw Error.synchronizePreferencesFailed
        }
    }
}
