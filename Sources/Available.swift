//
//  Available.swift
//  PandaMom
//
//  Copyright (c) 2017 Javier Zhang (https://wordlessj.github.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

private let capturedVersion = "(\\d+)[_.](\\d+)"
private let doubleVersion = "\(capturedVersion)\\s*,\\s*\(capturedVersion)"

private let availableRegexes = [
    try! NSRegularExpression(pattern: "AVAILABLE_IOS[\\w_]*\\s*\\(\(capturedVersion)",
                             options: .caseInsensitive),
    try! NSRegularExpression(pattern: "AVAILABLE\\s*\\(\\d+[_.]\\d+\\s*,\\s*\(capturedVersion)",
                             options: .caseInsensitive),
    try! NSRegularExpression(pattern: "API_AVAILABLE\\(ios\\(\(capturedVersion)",
                             options: .caseInsensitive),
]

private let deprecatedRegexes = [
    try! NSRegularExpression(pattern: "DEPRECATED_IOS\\s*\\(\(doubleVersion)",
                             options: .caseInsensitive),
    try! NSRegularExpression(pattern: "API_DEPRECATED[\\w_]*\\(.*ios\\(\(doubleVersion)",
                             options: .caseInsensitive),
]

enum Deprecated {
    case yes
    case no
    case version(String, String)
}

protocol Available {
    var macros: String { get }
}

extension Available {
    var available: String? {
        guard let result = matchMacros(availableRegexes) else { return nil }
        let substrings = macros.substrings(result)
        let major = Int(substrings[1])!
        let minor = Int(substrings[2])!
        guard isHigherThanMinimum(major: major, minor: minor) else { return nil }
        return "\(major).\(minor)"
    }

    var deprecated: Deprecated {
        guard let result = matchMacros(deprecatedRegexes) else { return .no }
        let substrings = macros.substrings(result)
        let introducedMajor = Int(substrings[1])!
        let introducedMinor = Int(substrings[2])!
        let deprecatedMajor = Int(substrings[3])!
        let deprecatedMinor = Int(substrings[4])!
        guard isHigherThanMinimum(major: deprecatedMajor, minor: deprecatedMinor) else { return .yes }
        return .version("\(introducedMajor).\(introducedMinor)", "\(deprecatedMajor).\(deprecatedMinor)")
    }

    var isDeprecated: Bool {
        switch deprecated {
        case .yes: return true
        default: return false
        }
    }

    private func matchMacros(_ regexes: [NSRegularExpression]) -> NSTextCheckingResult? {
        for regex in regexes {
            let result = regex.firstMatch(in: macros, range: NSRange(0..<macros.count))

            if result != nil {
                return result
            }
        }

        return nil
    }

    private func isHigherThanMinimum(major: Int, minor: Int) -> Bool {
        return major > Config.minimumMajorVersion ||
            (major == Config.minimumMajorVersion && minor > Config.minimumMinorVersion)
    }
}
