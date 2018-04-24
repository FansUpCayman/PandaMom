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

//        for m in type.methods {
//            string += method(m, type: type)
//        }

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

        string += "\n"
        string += availableAttribute(of: type, indent: false)
        string += "extension Element where Object: \(type.name) {\n"
        return string
    }

    private func property(_ property: Property, type: Type) -> String {
        var string = availableAttribute(of: property, indent: true)
        string += """
            @discardableResult
            public func \(property.nameWithoutPrefix)(_ value: \(property.type)) -> Self {
                return addAttributes(key: "\(property.name)", value: value) {
                    $0.\(property.name) = value\n
        """

        if type.isPropertyDirty(property) {
            string += "            $0.invalidateLayout()\n"
        }

        string += """
                }
            }\n\n
        """
        return string
    }

    private func method(_ method: Method, type: Type) -> String {
        let firstPart = method.parts[0]
        let methodName = firstPart.name.initialLowercased()
        let firstFullName = firstPart.subname == firstPart.parameter ?
            firstPart.parameter : "\(firstPart.subname ?? "_") \(firstPart.parameter)"
        var string = availableAttribute(of: method, indent: true)
        string += """
                @discardableResult
                public func \(methodName)(\(firstFullName): \(firstPart.type)
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
            ) -> Self {
                    return addChangingAttributes(key: "\(methodName)") {
                        object.set\(firstPart.name)(\(subName)\(firstPart.parameter)
            """

        for part in method.parts.dropFirst() {
            string += ", \(part.name): \(part.parameter)"
        }

        string += """
            )
                    }
                }\n\n
            """
        return string
    }

    private func methodForMultiple(_ method: Method, type: Type) -> String {
        guard let multipleType = method.multipleType else { return "" }
        let available = availableAttribute(of: method, indent: true)
        let values = multipleType.values
        let firstPart = method.parts[0]
        let methodName = firstPart.name.initialLowercased()
        var string = ""

        for (index, value) in values.enumerated() {
            let upperValue = value.initialUppercased()
            let suffix = index == 0 ? "" : upperValue

            string += available
            string += """
                @discardableResult
                public func \(methodName)\(suffix)(_ value: \(firstPart.type)) -> Self {
                    return addAttributes(key: "\(methodName)\(upperValue)", value: value) {
                        $0.set\(firstPart.name)(value, \(method.parts[1].name): .\(value))\n
            """

            if type.isMethodDirty(method) {
                string += "            $0.invalidateLayout()\n"
            }

            string += """
                    }
                }\n\n
            """
        }

        return string
    }

    private func footer() -> String {
        return "}\n"
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
}
