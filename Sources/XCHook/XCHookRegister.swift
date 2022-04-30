//
//  XCHookRegister.swift
//
//
//  Created by Takuto Nakamura on 2022/04/27.
//

import Foundation

public final class XCHookRegister {
    enum AlertEvents: String {
        case plain   = "Xcode.AlertEvents"
        case fourOne = "Xcode.AlertEvents.4_1"
    }

    lazy var xchookPath: String = {
        return homeDirectory() + "/.xchook"
    }()

    lazy var xcodePath: String = {
        return homeDirectory() + "/Library/Preferences/com.apple.dt.Xcode.plist"
    }()

    public init?() {
        let shellOutput = Shell.run("test", "-e", xcodePath)
        guard shellOutput.succeeded else { return nil }
    }

    func createXCHookDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: xchookPath) {
            try? fm.createDirectory(atPath: xchookPath,
                                    withIntermediateDirectories: true)
        }
    }

    func removeXCHookDirectory() {
        let fm = FileManager.default
        if fm.fileExists(atPath: xchookPath) {
            try? fm.removeItem(atPath: xchookPath)
        }
    }

    func copyFiles() {
        guard let resourcePath = Bundle.module.resourcePath else { return }
        let fm = FileManager.default
        let dirs = (try? fm.contentsOfDirectory(atPath: resourcePath)) ?? []
        var isDirectory: ObjCBool = false
        dirs.forEach { dir in
            let urlAt = URL(fileURLWithPath: resourcePath).appendingPathComponent(dir)
            var urlTo = URL(fileURLWithPath: xchookPath).appendingPathComponent(dir)
            fm.fileExists(atPath: urlAt.path, isDirectory: &isDirectory)
            if isDirectory.boolValue && urlAt.lastPathComponent == "run_scripts" {
                try? fm.copyItem(at: urlAt, to: urlTo)
            } else if urlAt.pathExtension == "txt" {
                urlTo.deletePathExtension()
                urlTo.appendPathExtension("swift")
                let data = try? Data(contentsOf: urlAt)
                let attr: [FileAttributeKey: Any] = [
                    .posixPermissions: NSNumber(value: 0o755)
                ]
                fm.createFile(atPath: urlTo.path, contents: data, attributes: attr)
            }
        }
    }

    private func getPlist(url: URL) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
            return plist as? [String: Any]
        } catch {
            NSLog(error.localizedDescription)
            return nil
        }
    }

    func overwritePlist() {
        let url = URL(fileURLWithPath: xcodePath)
        overwritePlist(loadURL: url, writeURL: url)
    }

    @discardableResult
    func overwritePlist(loadURL: URL, writeURL: URL) -> Bool {
        guard let plist = getPlist(url: loadURL) else { return false }
        do {
            let newDict = Merge(xchookPath).overwrite(dict: plist)
            let data = try PropertyListSerialization.data(fromPropertyList: newDict,
                                                          format: .binary,
                                                          options: .zero)
            try data.write(to: writeURL, options: .atomic)
            return true
        } catch {
            NSLog(error.localizedDescription)
            return false
        }
    }

    func resetPlist() {
        let url = URL(fileURLWithPath: xcodePath)
        resetPlist(loadURL: url, writeURL: url)
    }

    @discardableResult
    func resetPlist(loadURL: URL, writeURL: URL) -> Bool {
        guard let plist = getPlist(url: loadURL) else { return false }
        do {
            let newDict = Merge(xchookPath).reset(dict: plist)
            let data = try PropertyListSerialization.data(fromPropertyList: newDict,
                                                          format: .binary,
                                                          options: .zero)
            try data.write(to: writeURL, options: .atomic)
            return true
        } catch {
            NSLog(error.localizedDescription)
            return false
        }
    }

    // For Unit Test
    func modulePlist(name: String) -> URL? {
        return Bundle.module.url(forResource: "plists/\(name)",
                                 withExtension: "plist")
    }

    public func install() {
        createXCHookDirectory()
        copyFiles()
        overwritePlist()
    }

    public func uninstall() {
        resetPlist()
        removeXCHookDirectory()
    }

    func homeDirectory() -> String {
        return FileManager.homeDirectory ?? NSHomeDirectory()
    }
}
