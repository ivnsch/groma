//
//  Operators.swift
//  shoppin
//
//  Created by ischuetz on 09/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


// TODO for now duplicate with Provider project, for some reason main project can't use it
infix operator >>> {associativity right precedence 90}
public func >>> <T, R>(x: T, f: (T) -> R) -> R {
    return f(x)
}
