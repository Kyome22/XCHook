/*
 XCHookDirectory.swift
 XCHook

 Created by Takuto Nakamura on 2026/07/04.
 */

import Foundation

struct XCHookDirectory: Sendable {
    let baseURL: URL

    static let `default` = XCHookDirectory(
        baseURL: FileManager.homeDirectoryURL.appending(path: ".xchook")
    )

    var runScriptsDirectoryURL: URL {
        baseURL.appending(path: "run_scripts")
    }

    var eventsDirectoryURL: URL {
        baseURL.appending(path: "events")
    }
}
