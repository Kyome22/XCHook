//
//  XCHookReceiver.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/27.
//

import Foundation
import Combine

public enum XCHookStatus: String {
    case buildStart      = "BUILD_START"
    case buildSucceeds   = "BUILD_SUCCEEDS"
    case buildFails      = "BUILD_FAILS"
    case testingStart    = "TESTING_START"
    case testingSucceeds = "TESTING_SUCCEEDS"
    case testingFails    = "TESTING_FAILS"
}

public struct XCHookEvent {
    let project: String
    let status: XCHookStatus
}

public final class XCHookReceiver {
    static let shared = XCHookReceiver()

    private var cancelables = Set<AnyCancellable>()
    private let xchookSubject = PassthroughSubject<XCHookEvent, Never>()
    public var xchookPublisher: AnyPublisher<XCHookEvent, Never> {
        return xchookSubject.eraseToAnyPublisher()
    }

    private init() {
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("postFromXCHook"))
            .sink { notification in
                guard let jsonStr = notification.object as? String,
                      let data = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data),
                      let dict = json as? [String: String]
                else { return }

                guard let project = dict["project"],
                      let _status = dict["status"],
                      let status = XCHookStatus(rawValue: _status)
                else { return }

                let event = XCHookEvent(project: project, status: status)
                self.xchookSubject.send(event)
            }
            .store(in: &cancelables)
    }
}
