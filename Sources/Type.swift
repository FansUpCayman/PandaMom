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
    var macros: String
    var properties: [Property]

    var isValid: Bool {
        return !isDeprecated && !Config.excludedTypes.contains(name)
    }

    var typesIfOptional: [String]? {
        return Config.optionalMap[name]
    }

    var imports: Set<String> {
        var imports = Set<String>()

        for property in properties {
            let prefix = String(property.type.prefix(2))

            if let framework = Config.frameworkMap[prefix] {
                imports.insert(framework)
            }
        }

        return imports
    }

    init(name: String, macros: String = "", properties: [Property] = []) {
        self.name = name
        self.macros = macros
        self.properties = properties
    }

    mutating func add(_ p: [Property]) {
        properties.append(contentsOf: p)
    }

    func isPropertyValid(_ property: Property) -> Bool {
        return !property.attributes.contains("class") &&
            !property.attributes.contains("readonly") &&
            !property.macros.contains("UIKIT_AVAILABLE_TVOS_ONLY") &&
            !property.isDeprecated &&
            !Config.excludedProperties.contains(fullname(property.name))
    }

    func swiftType(of property: Property) -> String {
        let parser = TypeParser()
        let (name, isClosure) = parser.parse(property.type)
        var fullType = Config.typeExceptions[fullname(property.name)] ?? name

        if property.attributes.contains("nullable") || property.attributes.contains("null_resettable") {
            if isClosure {
                fullType = "(\(fullType))?"
            } else {
                fullType += "?"
            }
        }

        return fullType
    }

    func swiftName(of property: Property) -> String {
        let attributes = property.attributes

        if let result = getterRegex.firstMatch(in: attributes, range: NSRange(0..<attributes.count)) {
            return attributes.substrings(result)[1]
        } else {
            return Config.nameMap[fullname(property.name)] ?? property.name
        }
    }

    private func fullname(_ propertyName: String) -> String {
        return "\(name).\(propertyName)"
    }
}

extension Type {
    static func + (lhs: Type, rhs: Type) -> Type {
        var type = lhs
        type.add(rhs.properties)
        return type
    }
}

extension Type: Available {
    var isClass: Bool { return true }
}
