//
//  NotEmptyTrimmedRule.swift
//  shoppin
//
//  Created by ischuetz on 22/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import SwiftValidator

public class NotEmptyTrimmedRule: Rule {
    
    private var message: String

    public init(message: String) {
        self.message = message
    }
    
    public func validate(value: String) -> Bool {
        return !value.trim().characters.isEmpty
    }
    
    public func errorMessage() -> String {
        return message
    }
}
