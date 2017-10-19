//
//  main.swift
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

private func markContainers(_ types: [String: Type]) -> [String: Type] {
    let parser = TypeParser()
    var types = types

    for (name, type) in types {
        for (index, property) in type.properties.enumerated() {
            let elementType = parser.elementType(property.type)

            if types[elementType.name] != nil {
                types[elementType.name]!.isConvertible = true
                types[name]!.properties[index].elementType = elementType
            }
        }

        for (index, method) in type.methods.enumerated() {
            let elementType = parser.elementType(method.parts[0].type)

            if types[elementType.name] != nil {
                types[elementType.name]!.isConvertible = true
                types[name]!.methods[index].parts[0].elementType = elementType
            }
        }
    }

    return types
}

let startDate = Date()

let files = Files()
let parser = Parser()
let generator = Generator()

for framework in Config.frameworks {
    var types = [String: Type]()

    print("Parsing \(framework)")

    for file in files.sourceFiles(framework: framework) {
        let string = try! String(contentsOfFile: file)
        let newTypes = parser.parse(string)
        types.merge(newTypes, uniquingKeysWith: +)
    }

    print("Generating \(framework)")

    types = markContainers(types)
    files.createOutputDirectory(framework: framework)

    for (name, type) in types {
        let string = generator.generate(type: type, framework: framework)
        files.save(string, framework: framework, name: name)
    }
}

print("Completed!")

let time = Date().timeIntervalSince(startDate)
print(String(format: "Time: %.2fs", time))
