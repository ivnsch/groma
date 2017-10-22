//
//  DBFraction.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import UIKit
import RealmSwift


// See https://github.com/realm/realm-cocoa/issues/1192 for explanations about compoundKey and setters.

public class DBFraction: Object {
    
    @objc public dynamic var numerator: Int = 0
    @objc public dynamic var denominator: Int = 0
    
    public func setNumerator(numerator: Int) {
        self.numerator = numerator
        compoundKey = compoundKeyValue()
    }
    
    public func setDenominator(denominator: Int) {
        self.denominator = denominator
        compoundKey = compoundKeyValue()
    }
    
    public convenience init(numerator: Int, denominator: Int) {
        self.init()
        setNumerator(numerator: numerator)
        setDenominator(denominator: denominator)
    }
    
    @objc public dynamic var compoundKey: String = "0-"
    
    public override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(numerator)-\(denominator)"
    }
    
    // MARK: - Filters
    
    static func createFilter(fraction: DBFraction) -> String {
        return createFilter(numerator: fraction.numerator, denominator: fraction.denominator)
    }
    
    static func createFilter(numerator: Int, denominator: Int) -> String {
        return "numerator == \(numerator) && denominator == \(denominator)"
    }
    
    // MARK: -
    
    public var decimalValue: Float {
        guard denominator != 0 else {logger.e("Invalid state: denominator is 0. Returning 0"); return 0}
        return (Float(numerator) / Float(denominator))
    }
    
    public var isZero: Bool {
        return decimalValue == 0
    }
    
    public var isOne: Bool {
        return decimalValue == 1
    }
    
    public var isValid: Bool {
        return denominator != 0
    }
    
    public var isValidAndNotZeroOrOne: Bool {
        return isValid && !isZero && !isOne
    }
    
    public override var description: String {
        return "\(numerator)/\(denominator)"
    }
    
    public static var zero: DBFraction {
        return DBFraction(numerator: 0, denominator: 1)
    }
    
    public static var one: DBFraction {
        return DBFraction(numerator: 1, denominator: 1)
    }
    
    public var isOneByOne: Bool {
        return numerator == 1 && denominator == 1
    }
    
    public var isValidAndNotZeroOrOneByOne: Bool {
        return isValid && !isZero && !isOneByOne
    }
}
