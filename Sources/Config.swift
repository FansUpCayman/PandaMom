//
//  Config.swift
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

struct Config {
    static let minimumMajorVersion = 9
    static let minimumMinorVersion = 0

    static let frameworks = [
        "UIKit",
    ]

    static let types: Set = [
        "NSObject",
        "UIResponder",
    ]

    static let superTypes: Set = [
        "UICollectionReusableView",
        "UIControl",
        "UIScrollView",
        "UIView",
    ]

    static let typeMap = [
        "void": "Void",
        "BOOL": "Bool",
        "NSInteger": "Int",
        "NSUInteger": "Int",
        "size_t": "Int",
        "unsigned int": "UInt32",
        "float": "Float",
        "double": "Double",
        "SEL": "Selector",
    ]

    static let genericMap = [
        "Class": (any: "AnyClass", generic: "%@.Type"),
        "id": (any: "Any", generic: "%@"),
        "NSArray": (any: "[Any]", generic: "[%@]"),
        "NSDictionary": (any: "[AnyHashable: Any]", generic: "[%@: %@]"),
    ]

    static let prefixStrippings: Set = [
        "NSCalendar",
        "NSData",
        "NSDate",
        "NSFileWrapper",
        "NSIndexPath",
        "NSLocale",
        "NSProgress",
        "NSSet",
        "NSString",
        "NSTimeInterval",
        "NSTimeZone",
        "NSUndoManager",
        "NSURL",
    ]

    static let excludedProperties: Set = [
        "UILabel.font",
        "UISimpleTextPrintFormatter.font",
        "UITextField.font",
        "UITextView.font",
    ]

    static let excludedMethods: Set<String> = [
    ]

    static let optionalMap = [
        "UITextInput": ["UITextField", "UITextView"],
        "UITextInputTraits": ["UISearchBar", "UITextField", "UITextView"],
    ]

    static let propertyNameMap = [
        "UIView.maskView": "mask",
    ]

    static let dirtyNames: Set = [
        "UIButton.contentEdgeInsets",
        "UIButton.imageEdgeInsets",
        "UIButton.titleEdgeInsets",
        "UIButton.setAttributedTitle",
        "UIButton.setImage",
        "UIButton.setTitle",

        "UIImageView.animationImages",
        "UIImageView.highlightedImage",
        "UIImageView.image",

        "UILabel.attributedText",
        "UILabel.numberOfLines",
        "UILabel.text",
    ]
}
