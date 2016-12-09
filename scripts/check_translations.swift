#!/usr/bin/env swift

import Cocoa

// Checks localizable files for correct syntax

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


let localizablePath = "../en.lproj/Localizable.strings"

if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
    
    let path = NSURL(fileURLWithPath: localizablePath)
    
    do {
        let text2 = try String(contentsOfURL: path, encoding: NSUTF8StringEncoding)
        
        let lines = text2.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
//        placeholder_enter_email = "Enter your e-mail";

        let regex = try NSRegularExpression(pattern: "^.* = \".*\";$", options: [])
        
        for line in lines {
            
            if !line.isEmpty {
                let matches = regex.matchesInString(line, options:[], range: NSMakeRange(0, line.characters.count))
                //            print("matches: \(matches)")
                if matches.count != 1 {
                    print("Invalid line: \(line)")
                }
            }
        }
        
        print("Finish!")
    }
        
    catch let e {
        
        print("Error: \(e)")
    }
}
