#!/usr/bin/env swift

import Cocoa

// Prints all the strings from a localization file without keys or any characters except strings contents

print("Start...")

// src http://stackoverflow.com/a/32020715/930450
public extension String {
    
    public func rangeFromNSRange(aRange: NSRange) -> Range<String.Index> {
        let s = self.startIndex.advancedBy(aRange.location)
        let e = self.startIndex.advancedBy(aRange.location + aRange.length)
        return s..<e
    }
    public var ns : NSString {return self as NSString}
    public subscript (aRange: NSRange) -> String? {
        get {return self.substringWithRange(self.rangeFromNSRange(aRange))}
    }
}


let localizablePath = "../es.lproj/Localizable.strings"

if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
    
    let path = NSURL(fileURLWithPath: localizablePath)
    
    do {
        let text2 = try String(contentsOfURL: path, encoding: NSUTF8StringEncoding)
        
        let lines = text2.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        let regex = try NSRegularExpression(pattern: "\"(.*)\"", options: [])
        
        let matches = regex.matchesInString(text2, options:[], range: NSMakeRange(0, text2.characters.count))
        
        var keys: [String] = []
        
        for match in matches {
            let key = text2[match.rangeAtIndex(1)]!
            print(key)
        }
    }
        
    catch let e {
        
        print("Error: \(e)")
    }
}
