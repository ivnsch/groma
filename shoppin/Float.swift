//
//  Float.swift
//  shoppin
//
//  Created by ischuetz on 30.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension Float {
   
    func toString(maxFractionDigits:Int) -> String? {
        let nf = NSNumberFormatter()
        nf.numberStyle = .DecimalStyle
        nf.maximumFractionDigits = maxFractionDigits
        nf.minimumFractionDigits = 0
        let s2 = nf.stringFromNumber(NSNumber(float: self))
        return s2
    }
}
