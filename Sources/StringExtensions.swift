//
//  StringExtensions.swift
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

extension Character {
    var isLowercase: Bool {
        return ("a"..."z").contains(self)
    }

    var isUppercase: Bool {
        return ("A"..."Z").contains(self)
    }
}

extension String {
    var length: Int {
        return (self as NSString).length
    }

    func index(_ offset: Int) -> Index {
        return index(offset >= 0 ? startIndex : endIndex, offsetBy: offset)
    }

    func indexRange(_ range: Range<Int>) -> Range<Index> {
        return index(range.lowerBound)..<index(range.upperBound)
    }

    func substrings(_ result: NSTextCheckingResult) -> [String] {
        return (0..<result.numberOfRanges).map { index in
            let range = result.range(at: index)

            if range.location != NSNotFound {
                return (self as NSString).substring(with: range)
            } else {
                return ""
            }
        }
    }

    func initialLowercased() -> String {
        let i = index { $0.isLowercase } ?? endIndex
        let range = startIndex..<i
        return replacingCharacters(in: range, with: self[range].lowercased())
    }
}
