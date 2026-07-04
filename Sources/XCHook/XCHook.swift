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

    static let preferencesDomain = "com.apple.dt.Xcode"

    let xchookDirectoryURL: URL

    var runScriptsDirectoryURL: URL {
        xchookDirectoryURL.appending(path: "run_scripts")
    }

    var eventsDirectoryURL: URL {
        xchookDirectoryURL.appending(path: "events")
    }

    public init?() {
        guard let homeDirectory = FileManager.homeDirectory else { return nil }
        let xcodePreferencesPath = homeDirectory + "/Library/Preferences/\(Self.preferencesDomain).plist"
        guard FileManager.default.fileExists(atPath: xcodePreferencesPath) else { return nil }
        xchookDirectoryURL = URL(filePath: homeDirectory).appending(path: ".xchook")
    }

    init(xchookDirectoryURL: URL) {
        self.xchookDirectoryURL = xchookDirectoryURL
    }

    public func isInstalled() -> Bool {
        let merge = Merge(xchookDirectoryURL.path)
        guard merge.expectedScriptPaths.allSatisfy(FileManager.default.fileExists(atPath:)),
              let alertEvents = copyPreferenceValue(forKey: Merge.modernAlertEventsKey) else {
            return false
        }
        return merge.isRegistered(in: alertEvents)
    }

    public func install() throws {
        try createXCHookDirectories()
        try copyRunScripts()
        try applyBehaviors()
    }

    public func uninstall() throws {
        try resetBehaviors()
        try removeXCHookDirectory()
    }

    func createXCHookDirectories() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: runScriptsDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: eventsDirectoryURL, withIntermediateDirectories: true)
    }

    func removeXCHookDirectory() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: xchookDirectoryURL.path) {
            try fileManager.removeItem(at: xchookDirectoryURL)
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
            let destinationURL = runScriptsDirectoryURL.appending(path: scriptName)
            let attributes: [FileAttributeKey: Any] = [.posixPermissions: NSNumber(value: 0o755)]
            guard let scriptData = fileManager.contents(atPath: sourceURL.path),
                  fileManager.createFile(atPath: destinationURL.path, contents: scriptData, attributes: attributes) else {
                throw Error.copyRunScriptsFailed
            }
        }
    }

    func applyBehaviors() throws {
        let merge = Merge(xchookDirectoryURL.path)
        for key in Merge.alertEventsKeys {
            let currentValue = copyPreferenceValue(forKey: key) ?? [:]
            setPreferenceValue(merge.overwrite(dict: currentValue), forKey: key)
        }
        try synchronizePreferences()
    }

    func resetBehaviors() throws {
        let merge = Merge(xchookDirectoryURL.path)
        for key in Merge.alertEventsKeys {
            let currentValue = copyPreferenceValue(forKey: key) ?? [:]
            setPreferenceValue(merge.reset(dict: currentValue), forKey: key)
        }
        setPreferenceValue([String](), forKey: Merge.recentScriptsKey)
        try synchronizePreferences()
    }

    private func copyPreferenceValue(forKey key: String) -> [String: Any]? {
        CFPreferencesCopyValue(
            key as CFString,
            Self.preferencesDomain as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) as? [String: Any]
    }

    private func setPreferenceValue(_ value: Any, forKey key: String) {
        CFPreferencesSetValue(
            key as CFString,
            value as CFPropertyList,
            Self.preferencesDomain as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }

    private func synchronizePreferences() throws {
        let succeeded = CFPreferencesSynchronize(
            Self.preferencesDomain as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        guard succeeded else {
            throw Error.synchronizePreferencesFailed
        }
    }
}
