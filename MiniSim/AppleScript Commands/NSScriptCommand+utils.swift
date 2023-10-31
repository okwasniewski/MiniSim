//
//  NSScriptCommand+utils.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 18/06/2023.
//

import Foundation
import Cocoa

extension NSScriptCommand {
    func property(forKey key: String) -> Any? {
        if let evaluatedArguments = self.evaluatedArguments {
            if evaluatedArguments.keys.contains(key) {
                return evaluatedArguments[key]
            }
        }
        return nil
    }

    func encode<T>(_ value: T) throws -> String? where T: Encodable {
        let encoded = try JSONEncoder().encode(value)
        return String(data: encoded, encoding: .utf8)
    }
}
