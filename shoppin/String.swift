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
    
    // MARK: - Attributed text
    
    func makeAttributed(substring: String, normalFont: UIFont, font: UIFont, caseInsensitive: Bool = false) -> NSAttributedString {
        let substringRange = range(substring, caseInsensitive: caseInsensitive)
        return makeAttributed(substringRange, normalFont: normalFont, font: font)
    }

    func makeAttributed(range: NSRange?, normalFont: UIFont, font: UIFont, textColor: UIColor = UIColor.darkTextColor()) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSFontAttributeName: normalFont, NSForegroundColorAttributeName: textColor])
        if let range = range {
            attributedString.setAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: textColor], range: range)
        }
        return attributedString
    }
    
    // Convert entire string to attributed text without any specific attributes, this can be useful sometimes when we need our string to simply be an attributed text instance
    func toAttributedText() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        return attributedString
    }
    
    func makeAttributedBoldRegular(range: NSRange) -> NSAttributedString {
        return makeAttributed(range, normalFont: Fonts.regularLight, font: Fonts.regularBold)
    }
    
    func underline(range: NSRange) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: self)
        attributedText.addAttribute(NSUnderlineStyleAttributeName, value:NSUnderlineStyle.StyleSingle.rawValue, range: range)
        return attributedText
    }

    // See doc of firstRangeBetween
    // Additionally, note that every ocurrence of the separator is removed from the string at the end
    func underlineBetweenFirstSeparators(separator: String) -> NSMutableAttributedString {
        if let range = firstRangeBetween(separator) {
            let underlined = underline(range)
            underlined.mutableString.replaceOccurrencesOfString(separator, withString: "", options: [], range: fullRange)
            return underlined
        } else {
            return toAttributedText()
        }
    }
    
    // MARK: - Range
    
    var fullRange: NSRange {
        return NSMakeRange(0, self.characters.count)
    }
    
    // src: http://stackoverflow.com/a/27880748/930450
    func firstRangeOfRegex(regex: String) -> NSRange? {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = self as NSString
            let results = regex.matchesInString(self, options: [], range: NSMakeRange(0, nsString.length))
            return results.first?.range
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return nil
        }
    }
    
    // E.g. "Hello, %%this is string in between%% blablabla"
    // We pass the separator "%%" and this will return the range of the string between the first 2 separators, which is "this is string in between"
    // It also works if the string starts or ends with the separator
    // This only returns the string between the first 2 separators, if there are more separators, they are ignored
    // WARNING: If the string has no separators it returns the complete string, if it has only 1 separator it returns the string after the separator
    func firstRangeBetween(separator: String) -> NSRange? {
        let components = componentsSeparatedByString(separator)
        if let stringInBetween = components[safe: 1] {
            return range(stringInBetween)
        } else {
            print("Warn: String.firstRangeBetween: stringInBetween is nil - returning nil range")
            return nil
        }
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
    
    // MARK: -
    
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
    
    func size(font: UIFont) -> CGSize {
        return (self as NSString).sizeWithAttributes([NSFontAttributeName: font])
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