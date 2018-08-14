//
//  ProductGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class ProductGroup: DBSyncable, Identifiable, WithUuid {

    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var order: Int = 0
    @objc public dynamic var bgColorHex: String = "000000"
    @objc public dynamic var fav: Int = 0
    
    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    
    public convenience init(uuid: String, name: String, color: UIColor, order: Int, fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.color = color
        self.order = order
        self.fav = fav
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters

    static func createFilter(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }
    
    static func createFilterName(_ name: String) -> NSPredicate {
        return NSPredicate(format: "name = %@", name)
    }
    
    static func createFilterNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "name CONTAINS[c] %@", text)
    }
    
    static func createFilterUuids(_ uuids: [String]) -> NSPredicate {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return NSPredicate(format: "uuid IN {%@}", uuidsStr)
    }
    
    // MARK: - Update
    
    // Creates dictionary to update database entry for an order update
    static func createOrderUpdateDict(_ orderUpdate: OrderUpdate, dirty: Bool) -> [String: AnyObject] {
        return ["uuid": orderUpdate.uuid as AnyObject, "order": orderUpdate.order as AnyObject, DBSyncable.dirtyFieldName: dirty as AnyObject]
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject]) -> ProductGroup {
        let item = ProductGroup()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.order = dict["order"]! as! Int
        let colorStr = dict["color"]! as! String
        item.color = UIColor(hexString: colorStr)
        item.fav = dict["fav"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        //TODO!!!! items
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        // TODO!!!! items? we don't need this here correct?
        dict["order"] = order as AnyObject?
        dict["color"] = bgColorHex as AnyObject?
        dict["fav"] = fav as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    public func same(_ rhs: ProductGroup) -> Bool {
        return uuid == rhs.uuid
    }

    public var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }
    
    public override var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), bgColor: \(color.hexStr), order: \(order), fav: \(fav), removed: \(removed), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate.millisToEpochDate()), removed: \(removed)}"
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, bgColor: UIColor? = nil, order: Int? = nil, fav: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductGroup {
        return ProductGroup(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: bgColor ?? self.color,
            order: order ?? self.order,
            fav: fav ?? self.fav,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        DBProv.listItemGroupProvider.removeGroupDependenciesSync(realm, groupUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}
