//
//  Shell.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/09.
//

import Foundation

struct ShellOutput {
    let succeeded: Bool
    let outputs: [String]
    let errors: [String]

    init(
        terminationStatus: Int32,
        outputFileHandle: FileHandle,
        errorFileHandle: FileHandle
    ) {
        succeeded = (terminationStatus == 0)

        let outputData = outputFileHandle.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)
        outputs = output?.components(separatedBy: CharacterSet.newlines) ?? []

        let errorData = errorFileHandle.readDataToEndOfFile()
        let error = String(data: errorData, encoding: .utf8)
        errors = error?.components(separatedBy: CharacterSet.newlines) ?? []
    }

    func printOutput() {
        outputs.forEach { line in
            Swift.print(line)
        }
    }
}

struct Shell {
    @discardableResult
    static func run(_ args: String...) -> ShellOutput {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", args.joined(separator: " ")]
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        task.waitUntilExit()
        return ShellOutput(terminationStatus: task.terminationStatus,
                           outputFileHandle: outputPipe.fileHandleForReading,
                           errorFileHandle: errorPipe.fileHandleForReading)
    }
}
