//
//  String.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

public extension String {
    
    public func contains(_ str: String, caseInsensitive: Bool = false) -> Bool {
        
        var options = NSString.CompareOptions()
        if caseInsensitive {
            options = options.union(NSString.CompareOptions.caseInsensitive)
        }

        return self.range(of: str, options: options) != nil
    }
    
    public func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    public var floatValue: Float? {
        // Accepts , and . as separator
        return floatValueWithSeparator(separator: ".") ?? floatValueWithSeparator(separator: ",")
    }

    fileprivate func floatValueWithSeparator(separator: String) -> Float? {
        let formatter = NumberFormatter()
        formatter.isLenient = true
        formatter.decimalSeparator = separator
        return formatter.number(from: self)?.floatValue
    }
    
    public var boolValue: Bool? {
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
    
    public func makeAttributed(_ substring: String, normalFont: UIFont, font: UIFont, caseInsensitive: Bool = false) -> NSAttributedString {
        let substringRange = range(substring, caseInsensitive: caseInsensitive)
        return makeAttributed(substringRange, normalFont: normalFont, font: font)
    }

    public func makeAttributed(_ range: NSRange?, normalFont: UIFont, font: UIFont, textColor: UIColor = UIColor.darkText) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedStringKey.font: normalFont, NSAttributedStringKey.foregroundColor: textColor])
        if let range = range {
            attributedString.setAttributes([NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: textColor], range: range)
        }
        return attributedString
    }

    public func applyColor(ranges: [NSRange] = [], font: UIFont, color: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedStringKey.font: font])
        for range in ranges {
            attributedString.setAttributes([NSAttributedStringKey.foregroundColor: color], range: range)
        }
        return attributedString
    }

    public func applyBold(substring: String, font: UIFont, color: UIColor) -> NSAttributedString {
        if let range = range(substring, caseInsensitive: false) {
            return applyBoldColor(ranges: [range], font: font, color: color)
        } else {
            return NSAttributedString(string: self)
        }
    }

    public func applyBold(ranges: [NSRange] = [], font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedStringKey.font: font])
        for range in ranges {
            attributedString.setAttributes([NSAttributedStringKey.font: font.bold ?? {
                logger.e("Couldn't make font bold - using default font", .ui)
                return font
            } ()], range: range)
        }
        return attributedString
    }

    public func applyBoldColor(ranges: [NSRange] = [], font: UIFont, color: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedStringKey.font: font])
        for range in ranges {
            attributedString.setAttributes([NSAttributedStringKey.font: font.bold ?? {
                logger.e("Couldn't make font bold - using default font", .ui)
                return font
            } (), NSAttributedStringKey.foregroundColor: color], range: range)
        }
        return attributedString
    }


    // Convert entire string to attributed text without any specific attributes, this can be useful sometimes when we need our string to simply be an attributed text instance
    public func toAttributedText() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        return attributedString
    }

    public func underline(_ range: NSRange) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: self)
        attributedText.addAttribute(NSAttributedStringKey.underlineStyle, value:NSUnderlineStyle.styleSingle.rawValue, range: range)
        return attributedText
    }

    // See doc of firstRangeBetween
    // Additionally, note that every ocurrence of the separator is removed from the string at the end
    public func underlineBetweenFirstSeparators(_ separator: String) -> NSMutableAttributedString {
        if let range = firstRangeBetween(separator) {
            let underlined = underline(range)
            underlined.mutableString.replaceOccurrences(of: separator, with: "", options: [], range: fullRange)
            return underlined
        } else {
            return toAttributedText()
        }
    }
    
    // MARK: - Range
    
    public var fullRange: NSRange {
        return NSMakeRange(0, self.count)
    }
    
    // src: http://stackoverflow.com/a/27880748/930450
    public func firstRangeOfRegex(_ regex: String) -> NSRange? {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = self as NSString
            let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
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
    public func firstRangeBetween(_ separator: String) -> NSRange? {
        let components = self.components(separatedBy: separator)
        if let stringInBetween = components[safe: 1] {
            return range(stringInBetween)
        } else {
            print("Warn: String.firstRangeBetween: stringInBetween is nil - returning nil range")
            return nil
        }
    }
    
    public func range(_ str: String, caseInsensitive: Bool = false) -> NSRange? {
        
        var options = NSString.CompareOptions()
        if caseInsensitive {
            options = options.union(NSString.CompareOptions.caseInsensitive)
        }
        // Cast to NSString - It's currently a bit easier to work with NSRange, than convert between Range and NSRange (needed for e.g. attributedString)
        let range = (self as NSString).range(of: str, options: options)
        return range.location == NSNotFound ? nil : range
    }
    
    // MARK: -
    
    // replace possible spaces with spaces that look like spaces but don't cause line break
    public func noBreakSpaceStr() -> String {
        return replacingOccurrences(of: " ", with: "\u{00A0}")
    }
    
    // http://stackoverflow.com/a/30450559/930450
    // NOTE: FIXME: that returned height a bit short at least in HelpViewController (see comment there). Maybe related with missing NSParagraphStyleAttributeName attribute, wrapping etc?
    public func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    
    public func size(_ font: UIFont) -> CGSize {
        return (self as NSString).size(withAttributes: [NSAttributedStringKey.font: font])
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
    
    public func capitalizeFirst() -> String {
        if count > 0 {
            var copy = self
            copy.replaceSubrange(self.startIndex...self.startIndex, with: String(self[self.startIndex]).capitalized)
            return copy
        } else {
            return self
        }
    }
    
    public func uncapitalizeFirst() -> String {
        if count > 0 {
            var copy = self
            copy.replaceSubrange(self.startIndex...self.startIndex, with: String(self[self.startIndex]).lowercased())
            return copy
        } else {
            return self
        }
    }
}

public extension Optional where Wrapped == String {

    public func toNilIfEmpty() -> String? {
        if let str = self, !str.trim().isEmpty {
            return str
        } else {
            return nil
        }
    }
}
