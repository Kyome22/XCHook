//
//  XCHookReceiver.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/27.
//

import Foundation
import Combine

public enum XCHookStatus: String {
    case standby         = "STANDBY"
    case buildStart      = "BUILD_START"
    case buildSucceeds   = "BUILD_SUCCEEDS"
    case buildFails      = "BUILD_FAILS"
    case testingStart    = "TESTING_START"
    case testingSucceeds = "TESTING_SUCCEEDS"
    case testingFails    = "TESTING_FAILS"
}

public struct XCHookEvent {
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

    public static let standby = XCHookEvent(project: "",
                                            path: "",
                                            status: .standby,
                                            timestamp: "0.0")
}

public final class XCHookReceiver {
    public static let shared = XCHookReceiver()

    private var cancellables = Set<AnyCancellable>()
    private let xchookSubject = PassthroughSubject<XCHookEvent, Never>()
    public var xchookPublisher: AnyPublisher<XCHookEvent, Never> {
        return xchookSubject.eraseToAnyPublisher()
    }

    private init() {
        DistributedNotificationCenter
            .default()
            .publisher(for: Notification.Name("postFromXCHook"))
            .sink { notification in
                guard let jsonStr = notification.object as? String,
                      let data = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data),
                      let dict = json as? [String: String]
                else { return }

                guard let project = dict["project"],
                      let path = dict["path"],
                      let _status = dict["status"],
                      let status = XCHookStatus(rawValue: _status),
                      let timestamp = dict["timestamp"]
                else { return }

                let event = XCHookEvent(project: project,
                                        path: path,
                                        status: status,
                                        timestamp: timestamp)
                self.xchookSubject.send(event)
            }
            .store(in: &cancellables)
    }
}
