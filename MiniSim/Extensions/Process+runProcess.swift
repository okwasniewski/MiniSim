//
//  Process+runProcess.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import Foundation

extension Process {
    static func runProcess(fileURL: String, arguments: [String], waitUntilExit: Bool = true) throws -> String {
        let task = self.init()
        
        let executableURL = URL(fileURLWithPath: fileURL)
        
        let outputPipe = Pipe()
        
        task.executableURL = executableURL
        task.arguments = arguments
        task.standardOutput = outputPipe
        task.standardError = Pipe()
        
        try task.run()
        
        if waitUntilExit {
            task.waitUntilExit()
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        return output
    }
}
