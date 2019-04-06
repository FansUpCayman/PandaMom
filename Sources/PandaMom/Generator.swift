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

func generate(type: Type, framework: String) -> String {
    var result = header(type: type, framework: framework)

    for p in type.properties {
        result += property(p, type: type)
    }

    for m in type.methods {
        result += method(m, type: type)
    }

    for m in type.methods {
        result += methodForMultiple(m, type: type)
    }

    result.removeLast()
    result += footer()
    return result
}

private func header(type: Type, framework: String) -> String {
    let otherImports: String = type.imports.lazy
        .map { "import \($0)\n" }
        .joined()
    let available = availableAttribute(type.available, indent: false)

    return """
        //
        //  \(type.name).swift
        //  Panda
        //
        //  Baby of PandaMom. DO NOT TOUCH.
        //

        import \(framework)
        \(otherImports)\(
        type.isConvertible ?
        """

        \(available)public protocol \(type.name)Convertible {}

        \(available)extension \(type.name): \(type.name)Convertible {}
        \(available)extension PandaChain: \(type.name)Convertible {}

        """ :
        ""
        )
        \(available)extension PandaChain where Object: \(type.name) {

        """
}

private func property(_ property: Property, type: Type) -> String {
    let available = availableAttribute(property.available, indent: true)
    let attributes = property.isEscaping ? "@escaping " : ""
    let (propertyType, expression) = convertibleStuff(
        type: property.type,
        elementType: property.elementType,
        parameter: "value"
    )

    return """
        \(available)    @discardableResult
            public func \(property.name)(_ value: \(attributes)\(propertyType)) -> PandaChain {
                object.\(property.name) = \(expression)
                return self
            }\n\n
        """
}

private func method(_ method: Method, type: Type) -> String {
    let available = availableAttribute(method.available, indent: true)
    let methodName = method.nameWithoutSet
    let firstParam = method.parameters[0]
    let (firstParamType, expression) = convertibleStuff(
        type: firstParam.type,
        elementType: firstParam.elementType,
        parameter: firstParam.localName
    )
    let restParams = method.parameters.lazy.dropFirst()
    let restParamsString: String = restParams
        .map { ", \(fullName($0)): \($0.type)" }
        .joined()

    let subName: String

    switch firstParam.externalName {
    case "": subName = "\(firstParam.localName): "
    case "_": subName = ""
    default: subName = "\(firstParam.externalName): "
    }

    let restArguments = restParams
        .map { parameter in
            let externalName = parameter.externalName.isEmpty ? parameter.localName : parameter.externalName
            return ", \(externalName): \(parameter.localName)"
        }
        .joined()

    return """
        \(available)    @discardableResult
            public func \(methodName)(\(fullName(firstParam)): \(firstParamType)\(restParamsString)) -> PandaChain {
                object.\(method.name)(\(subName)\(expression)\(restArguments))
                return self
            }\n\n
        """
}

private func methodForMultiple(_ method: Method, type: Type) -> String {
    guard let multipleType = method.multipleType else { return "" }
    let available = availableAttribute(method.available, indent: true)
    let values = multipleType.values
    let methodName = method.nameWithoutSet
    var parameterType = method.parameters[0].type

    if parameterType.last! == "?" {
        parameterType.removeLast()
    }

    let restParameters: String = values.lazy
        .dropFirst()
        .map { value in
            """
            ,
                    \(value): \(parameterType)? = nil
            """
        }
        .joined()

    let arguments: String = values.lazy
        .map { "            \($0): \(parameterName($0)),\n" }
        .joined()

    return """
        \(available)    @discardableResult
            public func \(methodName)(
                _ \(parameterName(values[0])): \(parameterType)\(restParameters)
            ) -> PandaChain {
                return \(multipleType.methodName)(
        \(arguments)            setter: object.\(method.name)
                )
            }\n\n
        """
}

private func footer() -> String {
    return "}\n"
}

private func convertibleStuff(
    type: String,
    elementType: ElementType?,
    parameter: String
) -> (type: String, expression: String) {
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

private func availableAttribute(_ available: Available, indent: Bool) -> String {
    let indentString = indent ? "    " : ""
    var result = ""

    if let introduced = available.introduced {
        if let deprecated = available.deprecated {
            result = "\(indentString)@available(iOS, introduced: \(introduced), deprecated: \(deprecated))\n"
        } else if introduced > Config.minVersion {
            result = "\(indentString)@available(iOS \(introduced), *)\n"
        }
    }

    return result
}

private func fullName(_ parameter: Parameter) -> String {
    return parameter.externalName.isEmpty ?
        parameter.localName :
        "\(parameter.externalName) \(parameter.localName)"
}

private func parameterName(_ name: String) -> String {
    if name == "default" {
        return "d"
    } else {
        return name
    }
}
