//
//  Files.swift
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

class Files {
    private let sourcePathFormat = "/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform" +
        "/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/%@.framework"
    private let outputPath = try! FileManager.default
        .url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("PandaMom")

    func sourceFiles(framework: String) -> [String] {
        let frameworkPath = String(format: sourcePathFormat, framework)
        let subFrameworkPath = frameworkPath + "/Frameworks"
        var headersPaths = [frameworkPath + "/Headers"]

        if FileManager.default.fileExists(atPath: subFrameworkPath) {
            headersPaths += try! FileManager.default
                .contentsOfDirectory(atPath: subFrameworkPath)
                .map { (subFrameworkPath as NSString).appendingPathComponent($0 + "/Headers") }
        }

        return headersPaths.flatMap { path in
            try! FileManager.default
                .contentsOfDirectory(atPath: path)
                .map { (path as NSString).appendingPathComponent($0) }
        }
    }

    func createOutputDirectory(framework: String) {
        let path = outputPath.appendingPathComponent(framework)

        if FileManager.default.fileExists(atPath: path.path) {
            try! FileManager.default.removeItem(at: path)
        }

        try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
    }

    func save(_ string: String, framework: String, name: String) {
        let path = outputPath.appendingPathComponent(framework).appendingPathComponent("\(name).swift")
        try! string.write(to: path, atomically: true, encoding: .utf8)
    }
}
