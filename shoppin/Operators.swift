//
//  Operators.swift
//  shoppin
//
//  Created by ischuetz on 09/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

infix operator >> {associativity right precedence 90}
func >> <T, R>(x: T, f: (T) -> R) -> R {
    return f(x)
}
