import Foundation
import ShellOut

protocol ShellProtocol {
    @discardableResult static func execute(
        command: String,
        arguments: [String],
        atPath: String
    ) throws -> String
}

extension ShellProtocol {
    @discardableResult static func execute(
        command: String,
        arguments: [String] = [],
        atPath: String = "."
    ) throws -> String {
        try execute(command: command, arguments: arguments, atPath: atPath)
    }
}

final class Shell: ShellProtocol {
    @discardableResult static func execute(
        command: String,
        arguments: [String] = [],
        atPath: String = "."
    ) throws -> String {
        try shellOut(
            to: command,
            arguments: arguments,
            at: atPath
        )
    }
}
