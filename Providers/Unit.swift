//
//  Unit.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/02/2017.
//
//

import Foundation
import RealmSwift

/// Helper to identify internally (predefined) units, to assign them to predefined products or ingredients.
/// We could identify them by name but since this is translated it's a bit unreliable. Just a tiny bit though - a scenario where we store the units in one language and then change the language before the rest of prefill, where unit will be tried to identify with the new language, is extremely unlikely (actually impossible if we do everything in a databse transaction). But we don't want make assumptions and still be 110% sure that the prefilling works correctly + maybe there are other possible complications with the translations we haven't thought about.
/// Note that such scenarios can't happen with custom units entered by user - the user will select manually the units for products, and in possible case of changing the lang of the device, the user will continue to be able to recognize the units independently of the language (e.g. if unit was stored in Spanish, user changes lang to English, sees autosuggestion with Spanish unit, user will understand it).
public enum UnitId: Int {
    case none = 0
    case g = 1
    case kg = 2
    case ounce = 3
    case pack = 4
    case cup = 5
    case teaspoon = 6
    case spoon = 7
    case pinch = 8
    case pound = 9
    case liter = 10
    case milliliter = 11
    case drop = 12
    case shot = 13
    case clove = 14
    case can = 15
    case pint = 16
    case gin = 17
    case floz = 18
    case dash = 19
    case wgf = 20
    case dram = 21
    case lb = 22
    case oz = 23
    
    case custom = 99
}

public class Unit: DBSyncable, Identifiable, WithUuid {
    
    public static let unitsWithBase: [UnitId] = [.none, .g, .kg, .liter, .milliliter, .custom, .lb, .oz]

    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var idVal: Int = UnitId.none.rawValue
    
    @objc public dynamic var buyable: Bool = true
    
    public var id: UnitId {
        get {
            return UnitId(rawValue: idVal)!
        }
        set(newUnit) {
            idVal = newUnit.rawValue
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }

    public convenience init(uuid: String, name: String, id: UnitId, buyable: Bool) {
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.id = id
        self.buyable = buyable
    }

    // MARK: - Filters
    
    static func createFilter(uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }
    
    static func createFilter(id: UnitId) -> NSPredicate {
        return NSPredicate(format: "idVal = %@", id.rawValue)
    }
    
    static func createFilter(name: String) -> NSPredicate {
        return NSPredicate(format: "name = %@", name)
    }
    
    static func createFilterNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "name CONTAINS[c] %@", text)
    }
    
    static func createBuyable(buyable: Bool) -> NSPredicate {
        return NSPredicate(format: "buyable = %@", NSNumber(booleanLiteral: buyable))
    }

    // Used to convert List to Results
    static func createAlwaysTrueFilter() -> String {
        // There's should be something better than this...
        return "idVal >= 0"
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, id: UnitId? = nil, buyable: Bool = true) -> Unit {
        return Unit(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            id: id ?? self.id,
            buyable: buyable
        )
    }
       public override var description: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), id: \(id)}"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["id"]
    }
    
    // MARK: - Identifiable
    
    /**
     If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
     */
    public func same(_ rhs: Unit) -> Bool {
        return uuid == rhs.uuid
    }
}
