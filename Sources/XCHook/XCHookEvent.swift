/*
 XCHookEvent.swift
 XCHook

 Created by Takuto Nakamura on 2026/07/04.
 */

public struct XCHookEvent: Sendable, Equatable {
    public let project: String
    public let path: String
    public let status: XCHookStatus
    public let timestamp: Double

    public init(project: String, path: String, status: XCHookStatus, timestamp: Double) {
        self.project = project
        self.path = path
        self.status = status
        self.timestamp = timestamp
    }

    public static let standby = XCHookEvent(
        project: "",
        path: "",
        status: .standby,
        timestamp: 0
    )
}
