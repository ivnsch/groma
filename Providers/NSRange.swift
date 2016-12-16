//
//  NSRange.swift
//  shoppin
//
//  Created by ischuetz on 03/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension NSRange {
    public var end: Int {
        return location + length
    }
}
