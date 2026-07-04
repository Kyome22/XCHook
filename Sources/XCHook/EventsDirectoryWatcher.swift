/*
 EventsDirectoryWatcher.swift
 XCHook

 Created by Takuto Nakamura on 2026/07/04.
 */

import Foundation

final class EventsDirectoryWatcher: @unchecked Sendable {
    private struct Payload: Decodable {
        let project: String
        let path: String
        let status: String
        let timestamp: String
    }

    private let directoryURL: URL
    private let eventHandler: @Sendable (XCHookEvent) -> Void
    private let queue = DispatchQueue(label: "XCHook.EventsDirectoryWatcher")
    private var source: (any DispatchSourceFileSystemObject)?
    private var isStopped = false

    init(directoryURL: URL, eventHandler: @escaping @Sendable (XCHookEvent) -> Void) {
        self.directoryURL = directoryURL
        self.eventHandler = eventHandler
    }

    func start() {
        queue.async {
            self.discardStaleEventFiles()
            self.activate()
        }
    }

    func stop() {
        queue.async {
            self.isStopped = true
            self.cancelSource()
        }
    }

    private func activate() {
        guard !isStopped, source == nil else {
            return
        }
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileDescriptor = open(directoryURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            scheduleReactivation()
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            if source.data.isDisjoint(with: [.delete, .rename]) {
                self.drainEventFiles()
            } else {
                self.cancelSource()
                self.scheduleReactivation()
            }
        }
        source.setCancelHandler {
            close(fileDescriptor)
        }
        self.source = source
        source.activate()
        drainEventFiles()
    }

    private func cancelSource() {
        source?.cancel()
        source = nil
    }

    private func scheduleReactivation() {
        queue.asyncAfter(deadline: .now() + 1.0) {
            self.activate()
        }
    }

    private func discardStaleEventFiles() {
        eventFileURLs().forEach { fileURL in
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func drainEventFiles() {
        for fileURL in eventFileURLs() {
            defer {
                try? FileManager.default.removeItem(at: fileURL)
            }
            guard let data = try? Data(contentsOf: fileURL),
                  let payload = try? JSONDecoder().decode(Payload.self, from: data),
                  let status = XCHookStatus(rawValue: payload.status) else {
                continue
            }
            let event = XCHookEvent(
                project: payload.project,
                path: payload.path,
                status: status,
                timestamp: payload.timestamp
            )
            eventHandler(event)
        }
    }

    private func eventFileURLs() -> [URL] {
        let fileNames = (try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path)) ?? []
        return fileNames
            .filter { $0.hasSuffix(".json") && !$0.hasPrefix(".") }
            .sorted()
            .map { directoryURL.appending(path: $0) }
    }
}
