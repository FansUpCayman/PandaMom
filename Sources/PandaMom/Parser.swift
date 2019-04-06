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
import Regex

private let versionRegex = #"([\d\.]+)"#
private let introducedRegex = "(?:, introduced:)? \(versionRegex)"
private let deprecatedRegex = "(?:, deprecated: \(versionRegex))?"
private let availableRegex = #"(?:@available\(iOS\#(introducedRegex)\#(deprecatedRegex).*\n.*)?"#

private let classRegex = #"(?:class|protocol|extension) (\w+) *(?::[\w ,]+)?\{"#

private let prefixRegex = #"^ {4}((?:[@\w\(\)]+ )*)"#
private let typeRegex = #"([\w\.<>\[\]\(\) :&\?!]+)"#

private let accessRegex = #"(?: \{ (get)(?: (set))? \})?"#
private let propertyRegex = #"var (\w+): \#(typeRegex)\#(accessRegex)$"#

private let methodRegex = #"func (set\w+)\((.+)\)"#
private let parameterRegex = #"(?:([\w_]+) )?(\w+): \#(typeRegex)(?: =.+)?$"#

private let commentRegex = Regex(#" *(?://.*|/\*.*\*/)"#)
private let fullClassRegex = try! Regex(string: "\(availableRegex)\(classRegex)")
private let endRegex = Regex(#"^\}"#, options: .anchorsMatchLines)
private let fullPropertyRegex = try! Regex(
    string: "\(availableRegex)\(prefixRegex)\(propertyRegex)",
    options: .anchorsMatchLines
)
private let fullMethodRegex = try! Regex(
    string: "\(availableRegex)\(prefixRegex)\(methodRegex)",
    options: .anchorsMatchLines
)
private let fullParameterRegex = try! Regex(string: parameterRegex)

func parse(_ content: String) -> TypeCollection {
    var cleanContent = content

    while let result = commentRegex.firstMatch(in: cleanContent) {
        cleanContent.removeSubrange(result.range)
    }

    let endIndices = endRegex.allMatches(in: cleanContent).map { $0.range.lowerBound }
    var types = TypeCollection()

    for result in fullClassRegex.allMatches(in: cleanContent) {
        let captures = result.captures
        var type = Type(available: available(captures), name: captures[2]!)

        guard type.isValid else { continue }
        let endIndex = endIndices.first { $0 > result.range.upperBound }!
        let scope = String(cleanContent[result.range.upperBound..<endIndex])

        let (optionalProperties, properties) = parseProperties(scope)
            .lazy
            .filter(type.isPropertyValid)
            .divide { $0.modifiers.contains(.optional) }

        for type in typesIfOptional(type: type, properties: optionalProperties) {
            types.add(type)
        }

        type.properties += properties
        type.methods += parseMethods(scope).lazy.filter(type.isMethodValid)

        if !type.isEmpty {
            types.add(type)
        }
    }

    return types
}

private func parseProperties(_ content: String) -> [Property] {
    return fullPropertyRegex.allMatches(in: content).compactMap { result in
        let captures = result.captures
        guard !(captures[5] != nil && captures[6] == nil) else { return nil }
        return Property(
            available: available(captures),
            modifiers: modifiers(captures[2]),
            name: captures[3]!,
            type: captures[4]!,
            elementType: nil
        )
    }
}

private func parseMethods(_ content: String) -> [Method] {
    return fullMethodRegex.allMatches(in: content).compactMap { result in
        let captures = result.captures
        let parameters = parseParameters(captures[4]!)
        return parameters.isEmpty ? nil : Method(
            available: available(captures),
            modifiers: modifiers(captures[2]),
            name: captures[3]!,
            parameters: parameters
        )
    }
}

private func parseParameters(_ content: String) -> [Parameter] {
    var parameters = [Parameter]()

    for part in content.split(separator: ",") {
        guard let result = fullParameterRegex.firstMatch(in: String(part)) else { return [] }
        let captures = result.captures
        let parameter = Parameter(
            externalName: captures[0] ?? "",
            localName: captures[1]!,
            type: captures[2]!,
            elementType: nil
        )
        parameters.append(parameter)
    }

    return parameters
}

private func available(_ captures: [String?]) -> Available {
    return Available(
        introduced: captures[0].flatMap(Version.init),
        deprecated: captures[1].flatMap(Version.init)
    )
}

private func modifiers(_ capture: String?) -> Set<Modifier> {
    return Set((capture ?? "")
        .split(separator: " ")
        .compactMap { Modifier(rawValue: String($0)) })
}

private func typesIfOptional(type: Type, properties: [Property]) -> [Type] {
    if let names = type.typesIfOptional {
        return names.map { name in
            var type = Type(name: name)
            type.properties += properties
            return type
        }
    } else {
        for property in properties {
            print("!!! \(type.name).\(property.name) ignored")
        }

        return []
    }
}

private let arrayRegex = Regex(#"\[(\w+)\]"#)

func parseElementType(_ type: String) -> ElementType {
    if let result = arrayRegex.firstMatch(in: type) {
        return ElementType(name: result.captures[0]!, isArray: true)
    } else if type.hasSuffix("?") || type.hasSuffix("!") {
        return ElementType(name: String(type.dropLast()), isArray: false)
    } else {
        return ElementType(name: type, isArray: false)
    }
}
