//
//  LocalizedFloatRule.swift
//  Validator
//
//  Created by Cameron McCord on 5/5/15.
//  Copyright (c) 2015 jpotts18. All rights reserved.
//

import Foundation
import SwiftValidator

open class LocalizedFloatRule: Rule {
    
    fileprivate var message: String
    
    public init(message: String = "This must be a number with or without a decimal") {
        self.message = message
    }
    
    open func validate(_ value: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[-+]?(\\d*[.,])?\\d+", options: [])
            let match = regex.numberOfMatches(in: value, options: [], range: NSRange(location: 0, length: value.characters.count))
            return match == 1
            
        } catch _ {
            return false
        }
    }
    
    open func errorMessage() -> String {
        return message
    }
}
