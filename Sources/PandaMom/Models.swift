//
//  Models.swift
//  PandaMom
//
//  Copyright (c) 2018 Javier Zhang (https://wordlessj.github.io/)
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

struct Version {
    var major: Int
    var minor: Int

    init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    init?(_ string: String) {
        let splits = string.split(separator: ".")
        guard splits.count == 2,
            let major = Int(splits[0]),
            let minor = Int(splits[1])
            else { return nil }
        self.major = major
        self.minor = minor
    }
}

extension Version: Comparable {
    static func < (lhs: Version, rhs: Version) -> Bool {
        return lhs.major < rhs.major || (lhs.major == rhs.major && lhs.minor < rhs.minor)
    }
}

extension Version: CustomStringConvertible {
    var description: String { return "\(major).\(minor)" }
}

struct Available {
    var introduced: Version?
    var deprecated: Version?

    var isAvailableOnMinVersion: Bool {
        if let deprecated = deprecated {
            return deprecated > Config.minVersion
        } else {
            return true
        }
    }
}

enum Modifier: String {
    case `class`, optional, `static`
}

struct ElementType {
    var name: String
    var isArray: Bool
}

struct Property {
    var available: Available
    var modifiers: Set<Modifier>
    var name: String
    var type: String
    var elementType: ElementType?

    var isEscaping: Bool {
        return Config.escapings.contains(type)
    }
}

struct Parameter {
    var externalName: String
    var localName: String
    var type: String
    var elementType: ElementType?
}

struct Method {
    enum MultipleType: String {
        case controlState = "UIControl.State"
        case barMetrics = "UIBarMetrics"

        var values: [String] {
            switch self {
            case .controlState: return ["normal", "highlighted", "selected", "disabled"]
            case .barMetrics: return ["default", "compact", "defaultPrompt", "compactPrompt"]
            }
        }

        var methodName: String {
            var name = rawValue
            name.removeFirst(2)
            name.removeAll { $0 == "." }
            return "for" + name
        }
    }

    var available: Available
    var modifiers: Set<Modifier>
    var name: String
    var parameters: [Parameter]

    var nameWithoutSet: String {
        return String(name.dropFirst(3)).initialLowercased()
    }

    var multipleType: MultipleType? {
        if parameters.count == 2, let type = MultipleType(rawValue: parameters[1].type) {
            return type
        } else {
            return nil
        }
    }
}

struct Type {
    var available: Available
    var name: String
    var properties: [Property]
    var methods: [Method]
    var isConvertible: Bool

    var isValid: Bool { return available.isAvailableOnMinVersion }
    var typesIfOptional: [String]? { return Config.optionalMap[name] }
    var isEmpty: Bool { return properties.isEmpty && methods.isEmpty }

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

    init(available: Available = Available(), name: String) {
        self.available = available
        self.name = name
        properties = []
        methods = []
        isConvertible = false
    }

    func isPropertyValid(_ property: Property) -> Bool {
        return property.available.isAvailableOnMinVersion &&
            !property.modifiers.contains(.class) &&
            !property.modifiers.contains(.static) &&
            !Config.excludedProperties.contains(fullname(property.name))
    }

    func isMethodValid(_ method: Method) -> Bool {
        return method.available.isAvailableOnMinVersion &&
            !method.modifiers.contains(.class) &&
            !method.modifiers.contains(.static)
    }

    private func fullname(_ subName: String) -> String {
        return "\(name).\(subName)"
    }
}

struct TypeCollection {
    var types = [String: Type]()

    mutating func add(_ type: Type) {
        if var oldType = types[type.name] {
            oldType.properties += type.properties
            oldType.methods += type.methods
            types[type.name] = oldType
        } else {
            types[type.name] = type
        }
    }

    mutating func add(_ collection: TypeCollection) {
        for (_, type) in collection.types {
            add(type)
        }
    }

    mutating func markContainers() {
        for (name, type) in types {
            for (index, property) in type.properties.enumerated() {
                let elementType = parseElementType(property.type)

                if types[elementType.name] != nil {
                    types[elementType.name]!.isConvertible = true
                    types[name]!.properties[index].elementType = elementType
                }
            }

            for (index, method) in type.methods.enumerated() {
                let elementType = parseElementType(method.parameters[0].type)

                if types[elementType.name] != nil {
                    types[elementType.name]!.isConvertible = true
                    types[name]!.methods[index].parameters[0].elementType = elementType
                }
            }
        }
    }
}
