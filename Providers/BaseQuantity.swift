//
//  BaseQuantity.swift
//  Providers
//
//  Created by Ivan Schuetz on 22/02/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

// For now not referenced directly by other classes. We decided to implement BaseQuantity when implementing base quantity selectors - we now submit the base quantity before submitting the product, so we need base quantity to be separate.
public class BaseQuantity: DBSyncable {
    
    public dynamic var stringVal: String = ""
    
    public var floatValue: Float {
        get {
            return stringVal.floatValue ?? {
                QL3("Invalid base quantity string: \(stringVal). Returning 1 (no-op base quantity).")
                return 1
            }()
        }
        set(newValue) {
            stringVal = String(stringVal)
        }
    }
    
    public convenience init(_ stringVal: String) {
        self.init()
        self.stringVal = stringVal
    }
    
    public override static func primaryKey() -> String? {
        return "stringVal"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["floatValue"]
    }
    
    // MARK: - Filters
    
    static func createFilter(stringVal: String) -> String {
        return "stringVal == '\(stringVal)'"
    }
}
