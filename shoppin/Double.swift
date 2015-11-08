//
//  Double.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Double {

    // src http://stackoverflow.com/a/28075467/930450
    /**
    Returns a random floating point number between 0.0 and 1.0, inclusive.
    */
    public static func random() -> Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
}
