//
//  ProductGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class ProductGroup: DBSyncable, Identifiable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var order: Int = 0
    dynamic var bgColorHex: String = "000000"
    dynamic var fav: Int = 0
    
    var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    
    convenience init(uuid: String, name: String, color: UIColor, order: Int, fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.color = color
        self.order = order
        self.fav = fav
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterName(_ name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterUuids(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "uuid IN {\(uuidsStr)}"
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
    
    override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    func same(_ rhs: ProductGroup) -> Bool {
        return uuid == rhs.uuid
    }

    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }
    
    override var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), bgColor: \(color.hexStr), order: \(order), fav: \(fav), removed: \(removed), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate.millisToEpochDate()), removed: \(removed)}"
    }
    
    func copy(uuid: String? = nil, name: String? = nil, bgColor: UIColor? = nil, order: Int? = nil, fav: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductGroup {
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
        DBProviders.listItemGroupProvider.removeGroupDependenciesSync(realm, groupUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}


//
//
//class ProductGroup: Identifiable, Equatable {
//    
//    let uuid: String
//    let name: String
//    let bgColor: UIColor
//    var order: Int
//    var fav: Int
//    
//    //////////////////////////////////////////////
//    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
//    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
//    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
//    let lastServerUpdate: Int64?
//    let removed: Bool
//    //////////////////////////////////////////////
//    
//    init(uuid: String, name: String, bgColor: UIColor, order: Int, fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        self.uuid = uuid
//        self.name = name
//        self.bgColor = bgColor
//        self.order = order
//        self.fav = fav
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
//    }
//    
//    func copy(uuid: String? = nil, name: String? = nil, bgColor: UIColor? = nil, order: Int? = nil, fav: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductGroup {
//        return ProductGroup(
//            uuid: uuid ?? self.uuid,
//            name: name ?? self.name,
//            bgColor: bgColor ?? self.bgColor,
//            order: order ?? self.order,
//            fav: fav ?? self.fav,
//            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
//            removed: removed ?? self.removed
//        )
//    }
//    
//    func same(_ rhs: ProductGroup) -> Bool {
//        return uuid == rhs.uuid
//    }
//    
//    var shortDebugDescription: String {
//        return "{uuid: \(uuid), name: \(name), order: \(order)}"
//    }
//    
//    var debugDescription: String {
//        return "{\(type(of: self)) uuid: \(uuid), name: \(name), bgColor: \(bgColor.hexStr), order: \(order), fav: \(fav), removed: \(removed), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
//    }
//    
//    func equalsExcludingSyncAttributes(_ rhs: ProductGroup) -> Bool {
//        return uuid == rhs.uuid && name == rhs.name && bgColor == rhs.bgColor && order == rhs.order && fav == rhs.fav
//    }
//}
//
//func ==(lhs: ProductGroup, rhs: ProductGroup) -> Bool {
//    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
//}

