//
//  String+match.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 25/01/2023.
//

import Foundation

extension String {
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        let regexMatch = try? NSRegularExpression(pattern: regex, options: [])
        let match = regexMatch?.matches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length))
            .map { match in
            (0..<match.numberOfRanges).map { idx in
                match.range(at: idx).location == NSNotFound ? "" : nsString.substring(with: match.range(at: idx))
            }
        }
        return match ?? []
    }
}
