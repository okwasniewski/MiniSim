import Foundation
@testable import MiniSim

class ShellStub: ShellProtocol {
    private let queue = DispatchQueue(label: "com.minisim.shellstub", attributes: .concurrent)

    private var _lastExecutedCommand: String = ""
    private var _lastPassedArguments: [String] = []
    private var _lastPassedPath: String = ""
    private var _mockedExecute: ((String, [String], String) throws -> String)?

    var lastExecutedCommand: String {
        queue.sync { _lastExecutedCommand }
    }

    var lastPassedArguments: [String] {
        queue.sync { _lastPassedArguments }
    }

    var lastPassedPath: String {
        queue.sync { _lastPassedPath }
    }

    var mockedExecute: ((String, [String], String) throws -> String)? {
        get { queue.sync { _mockedExecute } }
        set { queue.async(flags: .barrier) { self._mockedExecute = newValue } }
    }

    func execute(command: String, arguments: [String], atPath: String) throws -> String {
        queue.async(flags: .barrier) {
            self._lastExecutedCommand = command
            self._lastPassedArguments = arguments
            self._lastPassedPath = atPath
        }

        if let mockedExecute = queue.sync(execute: { _mockedExecute }) {
            return try mockedExecute(command, arguments, atPath)
        }
        return ""
    }

    func tearDown() {
        queue.async(flags: .barrier) {
            self._lastExecutedCommand = ""
            self._lastPassedArguments = []
            self._lastPassedPath = ""
            self._mockedExecute = nil
        }
    }
}
