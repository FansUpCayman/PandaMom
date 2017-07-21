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

private let generalAvailableRegexes = availableRegexes(prefix: "AVAILABLE")
private let classAvailableRegexes = availableRegexes(prefix: "CLASS_AVAILABLE")
private let generalDeprecatedRegex = deprecatedRegex(prefix: "DEPRECATED")
private let classDeprecatedRegex = deprecatedRegex(prefix: "CLASS_DEPRECATED")

private let capturedVersion = "(\\d+)[_.](\\d+)"

private func availableRegexes(prefix: String) -> [NSRegularExpression] {
    return [
        try! NSRegularExpression(pattern: "\(prefix)_IOS[\\w_]*\\s*\\(\(capturedVersion)",
                                 options: .caseInsensitive),
        try! NSRegularExpression(pattern: "\(prefix)\\s*\\(\\d+[_.]\\d+\\s*,\\s*\(capturedVersion)",
                                 options: .caseInsensitive),
    ]
}

private func deprecatedRegex(prefix: String) -> NSRegularExpression {
    return try! NSRegularExpression(pattern: "\(prefix)_IOS\\s*\\(\(capturedVersion)\\s*,\\s*\(capturedVersion)",
                                    options: .caseInsensitive)
}

enum Deprecated {
    case yes
    case no
    case version(String, String)
}

protocol Available {
    var macros: String { get }
    var isClass: Bool { get }
}

extension Available {
    var available: String? {
        let regexes = isClass ? classAvailableRegexes : generalAvailableRegexes
        var result: NSTextCheckingResult?

        for regex in regexes {
            result = regex.firstMatch(in: macros, range: NSRange(0..<macros.count))

            if result != nil {
                break
            }
        }

        guard let r = result else { return nil }
        let substrings = macros.substrings(r)
        let major = Int(substrings[1])!
        let minor = Int(substrings[2])!
        guard isHigherThanMinimum(major: major, minor: minor) else { return nil }
        return "\(major).\(minor)"
    }

    var deprecated: Deprecated {
        let regex = isClass ? classDeprecatedRegex : generalDeprecatedRegex
        guard let result = regex.firstMatch(in: macros, range: NSRange(0..<macros.count)) else { return .no }
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

    private func isHigherThanMinimum(major: Int, minor: Int) -> Bool {
        return major > Config.minimumMajorVersion ||
            (major == Config.minimumMajorVersion && minor > Config.minimumMinorVersion)
    }
}
