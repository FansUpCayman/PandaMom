//
//  Method.swift
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

struct Method {
    enum MultipleType: String {
        case controlState = "UIControlState"
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
            return "for" + name
        }
    }

    struct Part {
        var name: String
        var type: String
        var parameter: String

        var swiftType: String {
            let parser = TypeParser()
            return parser.parse(type).name
        }
    }

    var parts: [Part]
    var macros: String

    var multipleType: MultipleType? {
        if parts.count == 2, let type = MultipleType(rawValue: parts[1].type) {
            return type
        } else {
            return nil
        }
    }
}

extension Method: Available {
    var isClass: Bool { return false }
}