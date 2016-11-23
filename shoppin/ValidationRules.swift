//
//  ValidationRules.swift
//  shoppin
//
//  Created by ischuetz on 14/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class ValidationRules {
    
    // for now not used but maybe later put all the rules here

    static func nameRules(_ minMsg: String, maxMsg: String) -> [Rule] {
        return minMaxLengthRules(1, minMsg: minMsg, maxLength: 50, maxMsg: maxMsg)
    }
    
    fileprivate static func minMaxLengthRules(_ minLength: Int, minMsg: String, maxLength: Int, maxMsg: String) -> [Rule] {
        return [
            MinLengthRule(length: minLength, message: minMsg),
            MinLengthRule(length: minLength, message: maxMsg)
        ]
    }
}
