//
//  Merge.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/11.
//

import Foundation

final class Merge {
    private enum AlertEvents: String {
        case plain   = "Xcode.AlertEvents"
        case fourOne = "Xcode.AlertEvents.4_1"
    }

    private enum AlertEvent: String {
        case buildStart      = "Xcode.AlertEvent.BuildStart"
        case buildSucceeds   = "Xcode.AlertEvent.BuildSucceeds"
        case buildFails      = "Xcode.AlertEvent.BuildFails"
        case testingStart    = "Xcode.AlertEvent.TestingStart"
        case testingSucceeds = "Xcode.AlertEvent.TestingSucceeds"
        case testingFails    = "Xcode.AlertEvent.TestingFails"

        var shell: String {
            switch self {
            case .buildStart:      return "build_start.sh"
            case .buildSucceeds:   return "build_succeeds.sh"
            case .buildFails:      return "build_fails.sh"
            case .testingStart:    return "testing_start.sh"
            case .testingSucceeds: return "testing_succeeds.sh"
            case .testingFails:    return "testing_fails.sh"
            }
        }
    }

    private let xchookPath: String
    private let setupDict: [String: Any]
    private let resetDict: [String: Any]
    private let alertEventList: [AlertEvent] = [
        .buildStart,
        .buildSucceeds,
        .buildFails,
        .testingStart,
        .testingSucceeds,
        .testingFails
    ]

    init(_ xchookPath: String) {
        self.xchookPath = xchookPath

        let fullDict = alertEventList
            .reduce(into: [String: Any](), { partialResult, event in
                partialResult[event.rawValue] = [
                    "Xcode.Alert.RunScript": [
                        "enabled": 1,
                        "path": "\(xchookPath)/run_scripts/\(event.shell)"
                    ]
                ]
            })
        self.setupDict = [
            AlertEvents.plain.rawValue: fullDict,
            AlertEvents.fourOne.rawValue: fullDict
        ]

        let emptyDict = alertEventList
            .reduce(into: [String: Any](), { partialResult, event in
                partialResult[event.rawValue] = [
                    "Xcode.Alert.RunScript": [
                        "enabled": 0,
                        "path": ""
                    ]
                ]
            })
        self.resetDict = [
            AlertEvents.plain.rawValue: emptyDict,
            AlertEvents.fourOne.rawValue: emptyDict
        ]
    }

    func overwrite(dict: [String: Any]) -> [String: Any] {
        return merge(old: dict, new: setupDict)
    }

    func reset(dict: [String: Any]) -> [String: Any] {
        var d = merge(old: dict, new: resetDict)
        d["Xcode.Alert.Script.Recent"] = []
        return d
    }

    private func merge(
        old: [String: Any],
        new: [String: Any]
    ) -> [String: Any] {
        var d = old
        let list: [AlertEvents] = [.plain, .fourOne]
        for events in list {
            d[events.rawValue] = mergeEvents(alertEvents: events, old: old, new: new)
        }
        return d
    }

    private func mergeEvents(
        alertEvents: AlertEvents,
        old: [String: Any],
        new: [String: Any]
    ) -> [String: Any] {
        let s = new[alertEvents.rawValue] as! [String: Any]
        if let t = old[alertEvents.rawValue] as? [String: Any] {
            var d = t
            for event in alertEventList {
                d[event.rawValue] = mergeEvent(alertEvent: event, old: t, new: s)
            }
            return d
        }
        return s
    }

    private func mergeEvent(
        alertEvent: AlertEvent,
        old: [String: Any],
        new: [String: Any]
    ) -> [String: Any] {
        let s = new[alertEvent.rawValue] as! [String: Any]
        if let t = old[alertEvent.rawValue] as? [String: Any] {
            return t.merging(s) { _, n in n }
        }
        return s
    }
}
