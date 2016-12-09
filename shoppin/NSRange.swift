//
//  NSRange.swift
//  shoppin
//
//  Created by ischuetz on 03/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension NSRange {
    var end: Int {
        return location + length
    }
}
