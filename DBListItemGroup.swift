//
//  DBListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItemGroup: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var order: Int = 0
    dynamic var bgColorHex: String = "000000"
    dynamic var fav: Int = 0
    
    func bgColor() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setBgColor(_ bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
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
    
    // MARK: - Update
    
    // Creates dictionary to update database entry for an order update
    static func createOrderUpdateDict(_ orderUpdate: OrderUpdate, dirty: Bool) -> [String: AnyObject] {
        return ["uuid": orderUpdate.uuid as AnyObject, "order": orderUpdate.order as AnyObject, DBSyncable.dirtyFieldName: dirty as AnyObject]
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject]) -> DBListItemGroup {
        let item = DBListItemGroup()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.order = dict["order"]! as! Int
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setBgColor(color)
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
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        DBProviders.listItemGroupProvider.removeGroupDependenciesSync(realm, groupUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}
