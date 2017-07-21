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

        for property in type.properties {
            string += function(type: type, property: property)
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

        if let attribute = availableAttribute(of: type) {
            string += attribute
        }

        string += "extension PandaChain where Object: \(type.name) {\n"
        return string
    }

    private func function(type: Type, property: Property) -> String {
        var string = ""

        if let attribute = availableAttribute(of: property) {
            string += "    "
            string += attribute
        }

        let name = type.swiftName(of: property)
        let propertyType = type.swiftType(of: property)
        let attributes = property.isEscaping ? "@escaping " : ""
        string += """
                @discardableResult
                public func \(name)(_ value: \(attributes)\(propertyType)) -> PandaChain {
                    object.\(name) = value
                    return self
                }\n\n
            """

        return string
    }

    private func footer() -> String {
        return "}\n"
    }

    private func availableAttribute(of a: Available) -> String? {
        if let version = a.available {
            return "@available(iOS \(version), *)\n"
        } else if case let .version(introduced, deprecated) = a.deprecated {
            return "@available(iOS, introduced: \(introduced), deprecated: \(deprecated))\n"
        } else {
            return nil
        }
    }
}
