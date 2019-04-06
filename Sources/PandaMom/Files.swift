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

private let fileManager = FileManager.default
private let desktopPath = try! fileManager
    .url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
private let sourcePath = desktopPath.appendingPathComponent("Frameworks")
private let outputPath = desktopPath.appendingPathComponent("PandaMom")

func sourceFiles() -> [String: [URL]] {
    let frameworks = try! fileManager.contentsOfDirectory(at: sourcePath, includingPropertiesForKeys: nil)
    var files = [String: [URL]]()

    for framework in frameworks {
        files[framework.lastPathComponent] = try? fileManager
            .contentsOfDirectory(at: framework, includingPropertiesForKeys: nil)
    }

    return files
}

func createOutputDirectory(framework: String) {
    let path = outputPath.appendingPathComponent(framework)

    if fileManager.fileExists(atPath: path.path) {
        try! fileManager.removeItem(at: path)
    }

    try! fileManager.createDirectory(at: path, withIntermediateDirectories: true)
}

func save(_ string: String, framework: String, name: String) {
    let path = outputPath.appendingPathComponent(framework).appendingPathComponent("\(name).swift")
    try! string.write(to: path, atomically: true, encoding: .utf8)
}
