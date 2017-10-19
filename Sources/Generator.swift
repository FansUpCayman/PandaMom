//
//  Generator.swift
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

class Generator {
    func generate(type: Type, framework: String) -> String {
        var string = header(type: type, framework: framework)

        for p in type.properties {
            string += property(p, type: type)
        }

        for m in type.methods {
            string += method(m, type: type)
        }

        for m in type.methods {
            string += methodForMultiple(m, type: type)
        }

        string.removeLast()
        string += footer()

        return string
    }

    private func header(type: Type, framework: String) -> String {
        var string = """
            //
            //  \(type.name).swift
            //  Panda
            //
            //  Baby of PandaMom. DO NOT TOUCH.
            //

            import \(framework)\n
            """

        for framework in type.imports {
            string += "import \(framework)\n"
        }

        let available = availableAttribute(of: type, indent: false)

        if type.isConvertible {
            string += "\n"
            string += available
            string += "public protocol \(type.name)Convertible {}\n\n"
            string += available
            string += "extension \(type.name): \(type.name)Convertible {}\n"
            string += available
            string += "extension PandaChain: \(type.name)Convertible {}\n"
        }

        string += "\n"
        string += available
        string += "extension PandaChain where Object: \(type.name) {\n"
        return string
    }

    private func property(_ property: Property, type: Type) -> String {
        let available = availableAttribute(of: property, indent: true)
        let attributes = property.isEscaping ? "@escaping " : ""
        let (propertyType, expression) = convertibleStuff(type: property.type,
                                                     elementType: property.elementType,
                                                     parameter: "value")

        return fullFunction(type: type, methodName: property.nameWithoutPrefix, originalName: property.name) { name in
            available + """
                    @discardableResult
                    public func \(name)(_ value: \(attributes)\(propertyType)) -> PandaChain {
                        object.\(property.name) = \(expression)
                        return self
                    }\n\n
                """
        }
    }

    private func method(_ method: Method, type: Type) -> String {
        let available = availableAttribute(of: method, indent: true)
        let firstPart = method.parts[0]
        let methodName = firstPart.name.initialLowercased()
        let (firstPartType, expression) = convertibleStuff(type: firstPart.type,
                                                      elementType: firstPart.elementType,
                                                      parameter: firstPart.parameter)

        return fullFunction(type: type, methodName: methodName, originalName: methodName) { name in
            let firstFullName = firstPart.subname == firstPart.parameter ?
                firstPart.parameter : "\(firstPart.subname ?? "_") \(firstPart.parameter)"
            var string = available

            string += """
                    @discardableResult
                    public func \(name)(\(firstFullName): \(firstPartType)
                """

            for part in method.parts.dropFirst() {
                if part.name == part.parameter {
                    string += ", \(part.name): \(part.type)"
                } else {
                    string += ", \(part.name) \(part.parameter): \(part.type)"
                }
            }

            let subName = firstPart.subname.map { $0 + ": " } ?? ""
            string += """
                ) -> PandaChain {
                        object.set\(firstPart.name)(\(subName)\(expression)
                """

            for part in method.parts.dropFirst() {
                string += ", \(part.name): \(part.parameter)"
            }

            string += """
                )
                        return self
                    }\n\n
                """

            return string
        }
    }

    private func methodForMultiple(_ method: Method, type: Type) -> String {
        guard let multipleType = method.multipleType else { return "" }
        let available = availableAttribute(of: method, indent: true)
        let values = multipleType.values
        let firstPart = method.parts[0]
        let methodName = firstPart.name.initialLowercased()
        var parameterType = firstPart.type

        if parameterType.last! == "?" {
            parameterType.removeLast()
        }

        return fullFunction(type: type, methodName: methodName, originalName: methodName) { name in
            var string = available

            string += """
                    @discardableResult
                    public func \(name)(
                        _ \(parameterName(values[0])): \(parameterType)
                """

            for value in values.dropFirst() {
                string += """
                    ,
                            \(value): \(parameterType)? = nil
                    """
            }

            string += "\n"
            string += """
                    ) -> PandaChain {
                        return \(multipleType.methodName)(\n
                """

            for value in values {
                string += """
                                \(value): \(parameterName(value)),\n
                    """
            }

            string += """
                            setter: object.set\(firstPart.name)
                        )
                    }\n\n
                """

            return string
        }
    }

    private func footer() -> String {
        return "}\n"
    }

    private func fullFunction(type: Type,
                              methodName: String,
                              originalName: String,
                              body: (String) -> String) -> String {
        let customName = type.customName(methodName)
        var string = ""

        if customName != methodName {
            string += "    /// `\(originalName)`\n"
            string += body(customName)
            string += "    @available(*, deprecated, renamed: \"\(customName)()\")\n"
        }

        string += body(methodName)
        return string
    }

    private func convertibleStuff(type: String,
                                  elementType: ElementType?,
                                  parameter: String) -> (type: String, expression: String) {
        let newType: String
        let expression: String

        if let elementType = elementType {
            newType = type.replacingOccurrences(of: elementType.name, with: elementType.name + "Convertible")

            if elementType.isArray {
                expression = "unboxArray(\(parameter))"
            } else {
                expression = "unbox(\(parameter))"
            }
        } else {
            newType = type
            expression = parameter
        }

        return (newType, expression)
    }

    private func availableAttribute(of a: Available, indent: Bool) -> String {
        let indentString = indent ? "    " : ""

        if let version = a.available {
            return "\(indentString)@available(iOS \(version), *)\n"
        } else if case let .version(introduced, deprecated) = a.deprecated {
            return "\(indentString)@available(iOS, introduced: \(introduced), deprecated: \(deprecated))\n"
        } else {
            return ""
        }
    }

    private func parameterName(_ name: String) -> String {
        if name == "default" {
            return "d"
        } else {
            return name
        }
    }
}
