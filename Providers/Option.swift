//
//  Option.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public extension Optional {
    
    public var isSet: Bool {
        return self != nil
    }
    
    func anyOrF(_ other: Wrapped?, _ f: (Wrapped, Wrapped) -> Wrapped?) -> Wrapped? {
        switch (self, other) {
        case (nil, nil): return nil
        case (let value, nil): return value
        case (nil, let value): return value
        case (let value1, let value2): return f(value1!, value2!)
        }
    }
    
    func fOrAny(_ other: Wrapped?, _ f: (Wrapped, Wrapped) -> Wrapped?) -> Wrapped? {
        switch (self, other) {
        case (nil, nil): return nil
        case (let value1, let value2) where value1 != nil && value2 != nil: return f(value1!, value2!)
        case (let value, nil): return value
        case (nil, let value): return value
        default: QL4("Logic error. Shouldn't be here."); return nil
        }
    }
}
