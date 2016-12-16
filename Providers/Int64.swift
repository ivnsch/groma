//
//  Int64.swift
//  shoppin
//
//  Created by ischuetz on 12/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

public extension Int64 {
    
    public func millisToEpochDate() -> Date {
        // TODO!!!! timezone?
        return Date(timeIntervalSince1970: TimeInterval(self / Int64(1000)))
    }
}
