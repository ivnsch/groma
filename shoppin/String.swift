//
//  String.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension String {
    
    func contains(str: String, caseInsensitive: Bool = false) -> Bool {
        
        var options = NSStringCompareOptions()
        if caseInsensitive {
            options = options.union(NSStringCompareOptions.CaseInsensitiveSearch)
        }

        return self.rangeOfString(str, options: options) != nil
    }

    func range(str: String, caseInsensitive: Bool = false) -> NSRange? {
        
        var options = NSStringCompareOptions()
        if caseInsensitive {
            options = options.union(NSStringCompareOptions.CaseInsensitiveSearch)
        }
        // Cast to NSString - It's currently a bit easier to work with NSRange, than convert between Range and NSRange (needed for e.g. attributedString)
        return (self as NSString).rangeOfString(str, options: options)
    }
    
    var floatValue: Float? {
        return NSNumberFormatter().numberFromString(self)?.floatValue
    }
    
    var boolValue: Bool? {
        switch self {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
    
    func makeAttributedBoldRegular(range: NSRange) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSFontAttributeName: Fonts.regularLight])
        attributedString.setAttributes([NSFontAttributeName: Fonts.regularBold], range: range)
        return attributedString
    }
    
//    func startsWith(str:String) -> Bool {
//        var startsWith = false
//        if let range = self.rangeOfString(str) {
//            
//            println (range)
//            println (range.startIndex)
//            // FIXME doesn't work when the found string is near to the end...
//            // e.g. self = "section1", str = "n"
//            // above prints:
////            6..<7
////            6
//            //and then:
//            //fatal error: can not increment endIndex
//            startsWith = distance(str.startIndex, range.startIndex) == 0
//        }
//        return startsWith
//    }
}