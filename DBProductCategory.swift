//
//  DBProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

class DBProductCategory: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"

    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    func color() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setColor(bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }

    convenience init(uuid: String, name: String, bgColorHex: String, lastUpdate: NSDate = NSDate(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.bgColorHex = bgColorHex
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, bgColorHex: String? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> DBProductCategory {
        return DBProductCategory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            bgColorHex: bgColorHex ?? self.bgColorHex,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterName(name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    static func createFilterDirtyAndValid() -> String {
        return "\(DBSyncable.dirtyFilter()) && uuid != ''"
    }
    
    // MARK: -
    static func fromDict(dict: [String: AnyObject]) -> DBProductCategory {
        let item = DBProductCategory()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setColor(color)
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        dict["color"] = bgColorHex
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override func deleteWithDependenciesSync(realm: Realm, markForSync: Bool) {
        DBProviders.productCategoryProvider.removeCategoryDependenciesSync(realm, categoryUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}