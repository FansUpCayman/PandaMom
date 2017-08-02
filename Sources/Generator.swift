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

        string += "\n"
        string += availableAttribute(of: type, indent: false)
        string += "extension PandaChain where Object: \(type.name) {\n"
        return string
    }

    private func property(_ property: Property, type: Type) -> String {
        let available = availableAttribute(of: property, indent: true)
        let methodName = type.swiftNameWithoutPrefix(of: property)
        let originalName = type.swiftName(of: property)
        let propertyType = type.swiftType(of: property)
        let attributes = property.isEscaping ? "@escaping " : ""

        return fullFunction(type: type, methodName: methodName, originalName: originalName) { name in
            available + """
                    @discardableResult
                    public func \(name)(_ value: \(attributes)\(propertyType)) -> PandaChain {
                        object.\(originalName) = value
                        return self
                    }\n\n
                """
        }
    }

    private func method(_ method: Method, type: Type) -> String {
        let available = availableAttribute(of: method, indent: true)
        let firstPart = method.parts[0]
        let (firstName, firstSubName) = type.swiftNames(of: firstPart)
        let methodName = firstName.initialLowercased()

        return fullFunction(type: type, methodName: methodName, originalName: methodName) { name in
            let firstFullName = firstSubName == firstPart.parameter ?
                firstPart.parameter : "\(firstSubName ?? "_") \(firstPart.parameter)"
            var string = available

            string += """
                    @discardableResult
                    public func \(name)(\(firstFullName): \(firstPart.swiftType)
                """

            for part in method.parts.dropFirst() {
                let name = type.swiftNames(of: part).0

                if name == part.parameter {
                    string += ", \(name): \(part.swiftType)"
                } else {
                    string += ", \(name) \(part.parameter): \(part.swiftType)"
                }
            }

            let subName = firstSubName.map { $0 + ": " } ?? ""
            string += """
                ) -> PandaChain {
                        object.set\(firstName)(\(subName)\(firstPart.parameter)
                """

            for part in method.parts.dropFirst() {
                string += ", \(type.swiftNames(of: part).0): \(part.parameter)"
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
        let firstName = type.swiftNames(of: firstPart).0
        let methodName = firstName.initialLowercased()
        var parameterType = firstPart.swiftType

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
                            setter: object.set\(firstName)
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
