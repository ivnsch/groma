//
//  BaseQuantity.swift
//  Providers
//
//  Created by Ivan Schuetz on 22/02/2017.
//
//

import UIKit
import RealmSwift


// For now not referenced directly by other classes. We decided to implement BaseQuantity when implementing base quantity selectors - we now submit the base quantity before submitting the product, so we need base quantity to be separate.
public class BaseQuantity: DBSyncable {
    
    fileprivate dynamic var valInternal: Float = 1
    
    public convenience init(_ val: Float) {
        self.init()
        setVal(val)
    }
    
    // We need custom setter because didSet doesn't work well with Realms
    public func setVal(_ val: Float) {
        self.valInternal = val
        myPrimaryKey = myPrimaryKeyValue()
    }
    
    // For consistency also a custom getter
    public var val: Float {
        return valInternal
    }
    
    // Realm doesn't support Float as primary key so we need this
    public dynamic var myPrimaryKey: String = "0-"
    
    public override static func primaryKey() -> String? {
        return "myPrimaryKey"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["val"]
    }
    
    private func myPrimaryKeyValue() -> String {
        return val.quantityString
    }
    
    // MARK: - Filters
    
    static func createFilter(val: Float) -> String {
        return "valInternal == \(val)"
    }
}
