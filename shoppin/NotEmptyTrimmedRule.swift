//
//  NotEmptyTrimmedRule.swift
//  shoppin
//
//  Created by ischuetz on 22/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import SwiftValidator

open class NotEmptyTrimmedRule: Rule {
    
    fileprivate var message: String

    public init(message: String) {
        self.message = message
    }
    
    open func validate(_ value: String) -> Bool {
        return !value.trim().isEmpty
    }
    
    open func errorMessage() -> String {
        return message
    }
}
