//
//  Parser.swift
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

private let typePattern = "[\\w\\s\\*<>_,]+"
private let methodPartPattern = "(\\w+):\\((\(typePattern))\\)(\\w+)"
private let macrosPattern = "[\\w\\s\\d\\(\\)_,]*"
private let fullMacrosPattern = "(\(macrosPattern)(?:\".*\")?\(macrosPattern))"

private let interfaceRegex = try! NSRegularExpression(
    pattern: "(CLASS.+\\n?)?@(?:interface|protocol)\\s+(\\w+)[^;\\n]*$",
    options: [.caseInsensitive, .anchorsMatchLines]
)
private let endRegex = try! NSRegularExpression(pattern: "@end", options: .caseInsensitive)
private let propertyClosureRegex = propertyRegex(isClosure: true)
private let propertyTypeRegex = propertyRegex(isClosure: false)
private let methodRegex = try! NSRegularExpression(
    pattern: "-\\s*\\(void\\)set((?:\(methodPartPattern)\\s*)+)\(fullMacrosPattern);",
    options: .caseInsensitive
)
private let methodPartRegex = try! NSRegularExpression(pattern: methodPartPattern, options: .caseInsensitive)

private func propertyRegex(isClosure: Bool) -> NSRegularExpression {
    var string = "@property\\s*(?:\\(([\\w\\s,=]+)\\))?\\s*"

    if isClosure {
        string += "(\\w+\\s+\\(\\^(\\w+)\\)\\(\\w*\\))"
    } else {
        let kindof = "(?:__kindof\\s+)?"
        let type = "(?:unsigned int|[\\w_]+)"
        let generics = "(?:<\(typePattern)>)?"
        let cComment = "(?:/\\*.*\\*/)?"
        string += "\(kindof)(\(type)\\s*\(generics))\\s*\(cComment)\\*?\\s*(\\w+)"
    }

    string += "\\s*\(fullMacrosPattern);"
    return try! NSRegularExpression(pattern: string, options: .caseInsensitive)
}

class Parser {
    private struct Member {
        var required: [Property]
        var optional: [Property]
        var methods: [Method]

        init() {
            required = []
            optional = []
            methods = []
        }
    }

    func parse(_ string: String) -> [String: Type] {
        var types = [String: Type]()
        var index = 0

        while let result = interfaceRegex.firstMatch(in: string, range: NSRange(index..<string.length)) {
            let substrings = string.substrings(result)
            let type = Type(name: substrings[2], macros: substrings[1])

            guard type.isValid else {
                index = result.range.upperBound
                continue
            }

            let restRange = result.range.upperBound..<string.length
            let endRange = endRegex.rangeOfFirstMatch(in: string, range: NSRange(restRange))

            let scopeRange = result.range.upperBound..<endRange.location
            let member = parseMembers(string, range: NSRange(scopeRange), type: type)

            if !member.required.isEmpty {
                types[type.name, default: type].add(member.required)
            }

            if !member.optional.isEmpty {
                if let names = type.typesIfOptional {
                    for name in names {
                        let newType = Type(name: name)
                        types[name, default: newType].add(member.optional)
                    }
                } else {
                    for property in member.optional {
                        print("!!! \(type.name).\(property.name) ignored")
                    }
                }
            }

            if !member.methods.isEmpty {
                types[type.name, default: type].add(member.methods)
            }

            index = endRange.upperBound
        }

        return types
    }

    private func parseMembers(_ string: String, range: NSRange, type: Type) -> Member {
        var isRequired = true
        var member = Member()

        (string as NSString).enumerateSubstrings(in: range, options: .byLines) { line, _, _, _ in
            guard let line = line else { return }

            if line.hasPrefix("@required") {
                isRequired = true
            } else if line.hasPrefix("@optional") {
                isRequired = false
            } else if line.hasPrefix("@property") {
                self.parseProperties(line, type: type, required: isRequired, member: &member)
            } else if line.hasPrefix("-") {
                self.parseMethods(line, type: type, member: &member)
            }
        }

        return member
    }

    private func parseProperties(_ line: String, type: Type, required: Bool, member: inout Member) {
        let regex = line.contains("^") ? propertyClosureRegex : propertyTypeRegex
        guard let result = regex.firstMatch(in: line, range: NSRange(0..<line.length)) else { return }

        let substrings = line.substrings(result)
        let property = Property(attributes: substrings[1],
                                type: substrings[2],
                                name: substrings[3],
                                macros: substrings[4])
        guard type.isPropertyValid(property) else { return }

        if required {
            member.required.append(property)
        } else {
            member.optional.append(property)
        }
    }

    private func parseMethods(_ line: String, type: Type, member: inout Member) {
        guard let result = methodRegex.firstMatch(in: line, range: NSRange(0..<line.length)) else { return }
        let substrings = line.substrings(result)
        let parts = substrings[1]
        var method = Method(parts: [], macros: substrings.last!)

        methodPartRegex.enumerateMatches(in: parts, range: NSRange(0..<parts.count)) { result, _, _ in
            guard let result = result else { return }
            let substrings = parts.substrings(result)
            let part = Method.Part(name: substrings[1],
                                   type: substrings[2],
                                   parameter: substrings[3])
            method.parts.append(part)
        }

        guard type.isMethodValid(method) else { return }
        member.methods.append(method)
    }
}
