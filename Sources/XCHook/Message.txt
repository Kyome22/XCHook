//
//  Message.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/09.
//

import Foundation

guard CommandLine.arguments.count == 3 else {
    NSLog("🔧 XCHook:Message.swift \(CommandLine.arguments.count)")
    exit(1)
}
let dict: [String: Any] = [
    "project": CommandLine.arguments[1],
    "status": CommandLine.arguments[2]
]
if let encodeData = try? JSONSerialization.data(withJSONObject: dict, options: []),
   let jsonStr = String(data: encodeData, encoding: .utf8) {
    let dnc = DistributedNotificationCenter.default()
    dnc.postNotificationName(NSNotification.Name("postFromXCHook"),
                             object: jsonStr,
                             deliverImmediately: true)
}
