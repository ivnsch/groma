//
//  Float.swift
//  shoppin
//
//  Created by ischuetz on 30.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

public extension Float {
   
    public static let formatter = NumberFormatter()
    public static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.currencySymbol = Locale.current.currencySymbol
        return f
    }()

    public static let quantityFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    public func toString(_ maxFractionDigits: Int) -> String {
        Float.formatter.numberStyle = .none
        Float.formatter.maximumFractionDigits = maxFractionDigits
        Float.formatter.minimumFractionDigits = 0
        return Float.formatter.string(from: NSNumber(value: self as Float))!
    }
    
    // TODO var
    public func toLocalCurrencyString() -> String {
        return Float.currencyFormatter.string(from: NSNumber(value: self))!
    }

    public var quantityStringHideZero: String {
        return self == 0 ? "" : Float.quantityFormatter.string(from: NSNumber(value: self))!
    }

    public var quantityStringHideLessOrEqualThan1: String {
        return self <= 1 ? "" : Float.quantityFormatter.string(from: NSNumber(value: self))!
    }

    public var quantityString: String {
        return Float.quantityFormatter.string(from: NSNumber(value: self))!
    }
}
