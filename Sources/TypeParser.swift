//
//  TypeParser.swift
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

private let closureRegex = try! NSRegularExpression(pattern: "(\\w+)\\s+\\(\\^\\w+\\)\\((\\w*)\\)",
                                                    options: .caseInsensitive)

private class ParserType {
    var name: String
    var generics: [ParserType]
    weak var superType: ParserType?

    init(superType: ParserType? = nil) {
        name = ""
        generics = []
        self.superType = superType
    }
}

class TypeParser {
    func parse(_ string: String) -> (name: String, isClosure: Bool) {
        if string.contains("^") {
            return (parseClosure(string), true)
        } else {
            return (parseType(string), false)
        }
    }

    private func parseClosure(_ string: String) -> String {
        guard let result = closureRegex.firstMatch(in: string, range: NSRange(0..<string.count)) else { return "" }
        let strings = string.substrings(result)
        let returnType = swiftName(strings[1])
        var parameter = swiftName(strings[2])

        if parameter == "Void" {
            parameter = ""
        }

        return "(\(parameter)) -> \(returnType)"
    }

    private func parseType(_ string: String) -> String {
        let baseType = ParserType()
        var currentType = baseType
        var buffer = ""
        var index = string.startIndex

        while index < string.endIndex {
            let char = string[index]

            switch char {
            case "0"..."9", "a"..."z", "A"..."Z":
                buffer.append(char)
            case "<":
                copyIfNeeded(&buffer, to: currentType)
                addGenericType(to: &currentType)
            case ">":
                copyIfNeeded(&buffer, to: currentType)
                currentType = currentType.superType!
            case ",":
                copyIfNeeded(&buffer, to: currentType)
                currentType = currentType.superType!
                addGenericType(to: &currentType)
            case " ":
                copyIfNeeded(&buffer, to: currentType)
            case "_":
                let attribute = "__kindof"

                if string[index..<string.endIndex].hasPrefix(attribute) {
                    index = string.index(index, offsetBy: attribute.count - 1)
                } else {
                    buffer.append(char)
                }
            default: break
            }

            index = string.index(after: index)
        }

        copyIfNeeded(&buffer, to: currentType)
        return fullname(baseType)
    }

    private func copyIfNeeded(_ buffer: inout String, to type: ParserType) {
        guard !buffer.isEmpty else { return }

        if !type.name.isEmpty {
            type.name += " "
        }

        type.name = swiftName(type.name + buffer)
        buffer.removeAll()
    }

    private func addGenericType(to type: inout ParserType) {
        let genericType = ParserType(superType: type)
        type.generics.append(genericType)
        type = genericType
    }

    private func swiftName(_ name: String) -> String {
        let swiftName: String

        if let t = Config.typeMap[name] {
            swiftName = t
        } else if Config.prefixStrippings.contains(name) {
            swiftName = name.substring(from: name.index(2))
        } else if name.hasSuffix("Ref") && name != "CFTypeRef" {
            swiftName = name.substring(to: name.index(-3))
        } else {
            swiftName = name
        }

        return swiftName
    }

    private func fullname(_ type: ParserType) -> String {
        let mainName = type.name
        let generics = type.generics.map { fullname($0) }

        var name = ""

        if generics.isEmpty {
            name += Config.genericMap[mainName]?.any ?? mainName
        } else {
            if let format = Config.genericMap[mainName]?.generic {
                if mainName == "id" && generics.count >= 2 {
                    name += "(\(generics.joined(separator: " & ")))"
                } else {
                    name += String(format: format, arguments: generics)
                }
            } else {
                name += "\(mainName)<\(generics.joined(separator: ", "))>"
            }
        }

        return name
    }
}
