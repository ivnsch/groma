//
//  Operators.swift
//  shoppin
//
//  Created by ischuetz on 09/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

precedencegroup Composition {
    higherThan: BitwiseShiftPrecedence
}

// TODO for now duplicate with Provider project, for some reason main project can't use it
infix operator >>> : Composition
public func >>> <T, R>(x: T, f: (T) -> R) -> R {
    return f(x)
}
