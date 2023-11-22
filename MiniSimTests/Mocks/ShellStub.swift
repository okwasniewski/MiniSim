import Foundation

@testable import MiniSim

class ShellStub: ShellProtocol {
    private(set) static var executedCommand: String = ""
    private(set) static var passedParameters: [String] = []
    private(set) static var passedPath: String = ""

    static func execute(command: String, arguments: [String], atPath: String) throws -> String {
        executedCommand = command
        passedParameters = arguments
        passedPath = atPath
        return ""
    }

    static func tearDown() {
        executedCommand = ""
        passedParameters = []
        passedPath = ""
    }
}
