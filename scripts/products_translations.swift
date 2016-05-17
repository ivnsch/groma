#!/usr/bin/env swift

import Cocoa

// TODO! must not overwrite not product related translations

// This script updates the translations with keys (normally product names) from suggestions prefiller.
// It iterates through the keys from suggestion prefiller, if a translation with this key already exists is re-inserted untouched, if not a new translation with empty value is inserted
// The translations will be in the same order as in suggestions prefiller.
// WARN: Assumes that the translation files contain only product names - any other translations (keys are not in suggestions prefiller) will be removed!

let suggestionsPrefillerPath = "../SuggestionsPrefiller.swift"

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


//print(NSFileManager().currentDirectoryPath)


func merge(translationsPath: String, keys: [String]) throws {
    
    let translationsDEPath = NSURL(fileURLWithPath: translationsPath)
    
    let currentTranslationsDEText = try String(contentsOfURL: translationsDEPath, encoding: NSUTF8StringEncoding)
    
    let regex2 = try NSRegularExpression(pattern: "(pr_.*) =.*\"", options: [])
    
    let matches2 = regex2.matchesInString(currentTranslationsDEText, options:[], range: NSMakeRange(0, currentTranslationsDEText.characters.count))
    
    var translationsDict: [String: String] = [:]
    var existingLines: [String] = []
    for match in matches2 {
        let line = currentTranslationsDEText[match.rangeAtIndex(0)]!
        let key = currentTranslationsDEText[match.rangeAtIndex(1)]!
        translationsDict[key] = line
        existingLines.append(line)
    }
    
    // if key exists in translations file, use it, otherwise insert a new translation with empty value.
    var linesStr: String = ""
    for key in keys {
        if let line = translationsDict[key] {
            linesStr = "\(linesStr)\n\(line);"
        } else {
            let keyLine = "\(key) = \"\";"
            linesStr = "\(linesStr)\n\(keyLine)"
            
        }
    }
    
//    print(linesStr)
    
    try linesStr.writeToURL(translationsDEPath, atomically: false, encoding: NSUTF8StringEncoding)
    print("Wrote translations to: \(translationsDEPath)")
}


if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {

    let path = NSURL(fileURLWithPath: suggestionsPrefillerPath)
    
    do {
        let text2 = try String(contentsOfURL: path, encoding: NSUTF8StringEncoding)

        let lines = text2.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

//        let str = ""
        let regex = try NSRegularExpression(pattern: "(pr_.*)\"", options: [])
        
        let matches = regex.matchesInString(text2, options:[], range: NSMakeRange(0, text2.characters.count))
        
        var keys: [String] = []
        
        for match in matches {
            let key = text2[match.rangeAtIndex(1)]!
            keys.append(key)
        }
        
        try merge("../Base.lproj/Localizable.strings", keys: keys)
        try merge("../de.lproj/Localizable.strings", keys: keys)
        try merge("../en.lproj/Localizable.strings", keys: keys)
        try merge("../es.lproj/Localizable.strings", keys: keys)
        
        print("Finished!")
    }
        
    catch let e {
    
        print("Error: \(e)")
    }
}