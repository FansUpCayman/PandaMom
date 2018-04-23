//
//  Type.swift
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

private let getterRegex = try! NSRegularExpression(pattern: "getter\\s*=\\s*(\\w+)", options: .caseInsensitive)

struct Type {
    var name: String
    var superType: String
    var macros: String
    var properties = [Property]()
    var methods = [Method]()

    var isValid: Bool {
        return (
            Config.types.contains(name) ||
                Config.superTypes.contains(name) ||
                Config.superTypes.contains(superType) ||
                Config.optionalMap[name] != nil
            ) &&
            !isDeprecated
    }

    var typesIfOptional: [String]? {
        return Config.optionalMap[name]
    }

    init(name: String, superType: String = "", macros: String = "") {
        self.name = name
        self.superType = superType
        self.macros = macros
    }

    mutating func add(_ p: [Property]) {
        var p = p

        for (index, property) in p.enumerated() {
            p[index].type = swiftType(of: property)
            p[index].name = swiftName(of: property)
            p[index].nameWithoutPrefix = swiftNameWithoutPrefix(of: property)
        }

        properties.append(contentsOf: p)
    }

    mutating func add(_ m: [Method]) {
        var m = m

        for (i, method) in m.enumerated() {
            for (j, part) in method.parts.enumerated() {
                (m[i].parts[j].name, m[i].parts[j].subname) = swiftNames(of: part)
                m[i].parts[j].type = swiftType(of: part)
            }
        }

        methods.append(contentsOf: m)
    }

    func isPropertyValid(_ property: Property) -> Bool {
        return !property.attributes.contains("class") &&
            !property.attributes.contains("readonly") &&
            !property.macros.contains("UIKIT_AVAILABLE_TVOS_ONLY") &&
            !property.isDeprecated &&
            !Config.excludedProperties.contains(fullname(property.name))
    }

    func isMethodValid(_ method: Method) -> Bool {
        return !method.isDeprecated &&
            !Config.excludedMethods.contains(fullname("set" + method.parts[0].name))
    }

    func isPropertyDirty(_ property: Property) -> Bool {
        return Config.dirtyNames.contains(fullname(property.name))
    }

    func isMethodDirty(_ method: Method) -> Bool {
        return Config.dirtyNames.contains(fullname("set" + method.parts[0].name))
    }

    func customName(_ methodName: String) -> String {
        if let name = Config.customNameMap[methodName] {
            return name
        }

        let lowercaseName = methodName.lowercased()
        var customName = methodName

        if customName.count >= name.count &&
            lowercaseName.hasPrefix(name.dropFirst(2).lowercased()) {
            customName.removeFirst(name.count - 2)
        }

        for (string, custom) in Config.customNameRules {
            guard let range = customName.lowercased().range(of: string) else { continue }
            customName.replaceSubrange(range, with: custom)
        }

        return customName.initialLowercased()
    }

    private func swiftType(of property: Property) -> String {
        let parser = TypeParser()
        let (name, isClosure) = parser.parse(property.type)
        var fullType = name

        if property.attributes.contains("nullable") || property.attributes.contains("null_resettable") {
            if isClosure {
                fullType = "(\(fullType))?"
            } else {
                fullType += "?"
            }
        }

        return fullType
    }

    private func swiftName(of property: Property) -> String {
        let attributes = property.attributes

        if let result = getterRegex.firstMatch(in: attributes, range: NSRange(0..<attributes.count)) {
            return attributes.substrings(result)[1]
        } else {
            return swiftNameWithoutPrefix(of: property)
        }
    }

    private func swiftNameWithoutPrefix(of property: Property) -> String {
        return Config.propertyNameMap[fullname(property.name)] ?? property.name.initialLowercased()
    }

    private func swiftNames(of part: Method.Part) -> (String, String?) {
        if part.name.hasSuffix("AtIndex") {
            return (String(part.name[..<part.name.index(-5)]), nil)
        } else {
            let prepositions = ["For", "With", "In", "After"]

            for preposition in prepositions {
                var index: String.Index?

                if part.name.hasPrefix(preposition.lowercased()) {
                    index = part.name.index(preposition.count)
                } else if let range = part.name.range(of: preposition) {
                    index = range.upperBound
                }

                guard let i = index, part.name[i].isUppercase else { continue }
                let suffix = part.name[i...].lowercased()

                guard part.type.lowercased().contains(suffix) else { continue }

                if part.name.first!.isUppercase {
                    let endIndex = part.name.index(i, offsetBy: -preposition.count)
                    return (String(part.name[..<endIndex]), preposition.lowercased())
                } else {
                    return (String(part.name[..<i]), nil)
                }
            }

            return (part.name, nil)
        }
    }

    private func swiftType(of part: Method.Part) -> String {
        let parser = TypeParser()
        return parser.parse(part.type).name
    }

    private func fullname(_ subName: String) -> String {
        return "\(name).\(subName)"
    }
}

extension Type {
    static func + (lhs: Type, rhs: Type) -> Type {
        var type = lhs
        type.properties.append(contentsOf: rhs.properties)
        type.methods.append(contentsOf: rhs.methods)
        return type
    }
}

extension Type: Available {}
