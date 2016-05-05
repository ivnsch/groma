//
//  Float.swift
//  shoppin
//
//  Created by ischuetz on 30.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension Float {
   
    static let formatter = NSNumberFormatter()
    static let currencyFormatter: NSNumberFormatter = {
        let f = NSNumberFormatter()
        f.numberStyle = .CurrencyStyle
        f.locale = NSLocale.currentLocale()
        return f
    }()
    
    func toString(maxFractionDigits: Int) -> String {
        Float.formatter.numberStyle = .NoStyle
        Float.formatter.maximumFractionDigits = maxFractionDigits
        Float.formatter.minimumFractionDigits = 0
        return Float.formatter.stringFromNumber(NSNumber(float: self))!
    }
    
    func toLocalCurrencyString() -> String {
        return Float.currencyFormatter.stringFromNumber(self)!
    }
}
