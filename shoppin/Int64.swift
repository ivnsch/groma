//
//  Int64.swift
//  shoppin
//
//  Created by ischuetz on 12/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

extension Int64 {
    
    func millisToEpochDate() -> NSDate {
        // TODO!!!! timezone?
        return NSDate(timeIntervalSince1970: NSTimeInterval(self / Int64(1000)))
    }
}
