import Foundation

@testable import MiniSim

class ShellStub: ShellProtocol {
    private(set) static var lastExecutedCommand: String = ""
    private(set) static var lastPassedArguments: [String] = []
    private(set) static var lastPassedPath: String = ""
    static var mockedExecute: ((_ command: String, _ arguments: [String], _ atPath: String) -> String)?

    static func execute(command: String, arguments: [String], atPath: String) throws -> String {
        lastExecutedCommand = command
        lastPassedArguments = arguments
        lastPassedPath = atPath
        if let mockedExecute {
            return mockedExecute(command, arguments, atPath)
        }
        return ""
    }

    static func tearDown() {
        lastExecutedCommand = ""
        lastPassedArguments = []
        lastPassedPath = ""
        mockedExecute = nil
    }
}
