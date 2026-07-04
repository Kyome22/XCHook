/*
 XCHookStatus.swift
 XCHook

 Created by Takuto Nakamura on 2026/07/04.
 */

public enum XCHookStatus: String, Sendable {
    case standby         = "STANDBY"
    case buildStart      = "BUILD_START"
    case buildSucceeds   = "BUILD_SUCCEEDS"
    case buildFails      = "BUILD_FAILS"
    case testingStart    = "TESTING_START"
    case testingSucceeds = "TESTING_SUCCEEDS"
    case testingFails    = "TESTING_FAILS"
}
