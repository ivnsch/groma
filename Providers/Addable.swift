//
//  Addable.swift
//  shoppin
//
//  Created by ischuetz on 23/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// needed to be able to do extension of e.g. Array<Int> or Dictionary<Hashable, Int>
// src http://stackoverflow.com/a/24225065/930450
public protocol Addable {
    init()
    static func + (lhs: Self, rhs: Self) -> Self
    static var identity: Self { get }
}

extension Int: Addable {
    public static var identity: Int {
        get {
            return 0
        }
    }
}

extension Double: Addable {
    public static var identity: Double {
        get {
            return 0
        }
    }
}
