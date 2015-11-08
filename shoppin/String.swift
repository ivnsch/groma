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
        let range = (self as NSString).rangeOfString(str, options: options)
        return range.location == NSNotFound ? nil : range
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
    
    func makeAttributed(substring: String, normalFont: UIFont, font: UIFont, caseInsensitive: Bool = false) -> NSAttributedString {
        let substringRange = range(substring, caseInsensitive: caseInsensitive)
        return makeAttributed(substringRange, normalFont: normalFont, font: font)
    }

    func makeAttributed(range: NSRange?, normalFont: UIFont, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSFontAttributeName: normalFont])
        if let range = range {
            attributedString.setAttributes([NSFontAttributeName: font], range: range)
        }
        return attributedString
    }
    
    func makeAttributedBoldRegular(range: NSRange) -> NSAttributedString {
        return makeAttributed(range, normalFont: Fonts.regularLight, font: Fonts.regularBold)
    }
    
    // replace possible spaces with spaces that look like spaces but don't cause line break
    func noBreakSpaceStr() -> String {
        return stringByReplacingOccurrencesOfString(" ", withString: "\u{00A0}")
    }
    
    // http://stackoverflow.com/a/30450559/930450
    // NOTE: FIXME: that returned height a bit short at least in HelpViewController (see comment there). Maybe related with missing NSParagraphStyleAttributeName attribute, wrapping etc?
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return boundingBox.height
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