/*
 XCHookReceiver.swift
 XCHook

 Created by Takuto Nakamura on 2022/04/27.
 */

import AsyncAlgorithms
import Foundation

public enum XCHookStatus: String, Sendable {
    case standby         = "STANDBY"
    case buildStart      = "BUILD_START"
    case buildSucceeds   = "BUILD_SUCCEEDS"
    case buildFails      = "BUILD_FAILS"
    case testingStart    = "TESTING_START"
    case testingSucceeds = "TESTING_SUCCEEDS"
    case testingFails    = "TESTING_FAILS"
}

public struct XCHookEvent: Sendable, Equatable {
    public let project: String
    public let path: String
    public let status: XCHookStatus
    public let timestamp: Double

    public init(project: String, path: String, status: XCHookStatus, timestamp: String) {
        self.project = project
        self.path = path
        self.status = status
        self.timestamp = Double(timestamp) ?? 0.0
    }

    public static let standby = XCHookEvent(
        project: "",
        path: "",
        status: .standby,
        timestamp: "0.0"
    )
}

public final class XCHookReceiver: Sendable {
    public static let shared = XCHookReceiver()

    public let events: any AsyncSequence<XCHookEvent, Never> & Sendable

    private init() {
        let eventsDirectoryURL = if let homeDirectory = FileManager.homeDirectory {
            URL(filePath: homeDirectory).appending(path: ".xchook/events")
        } else {
            URL(filePath: NSHomeDirectory()).appending(path: ".xchook/events")
        }
        events = Self.eventStream(directoryURL: eventsDirectoryURL).share(bufferingPolicy: .unbounded)
    }

    static func eventStream(directoryURL: URL) -> AsyncStream<XCHookEvent> {
        AsyncStream { continuation in
            let watcher = EventsDirectoryWatcher(directoryURL: directoryURL) { event in
                continuation.yield(event)
            }
            watcher.start()
            continuation.onTermination = { _ in
                watcher.stop()
            }
        }
    }
}
