/*
 XCHookReceiver.swift
 XCHook

 Created by Takuto Nakamura on 2022/04/27.
 */

import AsyncAlgorithms
import Foundation

public enum XCHookReceiver {
    public static let events: any AsyncSequence<XCHookEvent, Never> & Sendable = eventStream(
        directoryURL: XCHookDirectory.default.eventsDirectoryURL
    ).share(bufferingPolicy: .unbounded)

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
