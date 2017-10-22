//
//  ProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

// TODO rename in ItemCategory
public class ProductCategory: DBSyncable, Identifiable {
    
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var bgColorHex: String = "000000"

    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    public convenience init(uuid: String, name: String, color: UIColor, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init(uuid: uuid, name: name, color: color.hexStr, lastUpdate: lastUpdate, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    public convenience init(uuid: String, name: String, color: String, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.bgColorHex = color
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, lastUpdate: Date? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductCategory {
        return ProductCategory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: color ?? self.color,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
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
    
    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    static func createFilterDirtyAndValid() -> String {
        return "\(DBSyncable.dirtyFilter()) && uuid != ''"
    }
    
    // MARK: -
    static func fromDict(_ dict: [String: AnyObject]) -> ProductCategory {
        let item = ProductCategory()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.color = color
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["color"] = bgColorHex as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        DBProv.productCategoryProvider.removeCategoryDependenciesSync(realm, categoryUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    // MARK: -
    
    public func same(_ rhs: ProductCategory) -> Bool {
        return uuid == rhs.uuid
    }

    func equalsExcludingSyncAttributes(_ rhs: ProductCategory) -> Bool {
        return uuid == rhs.uuid && name == rhs.name && color == rhs.color
    }

    fileprivate func update(_ category: ProductCategory) -> ProductCategory {
        return copy(name: category.name, color: category.color, lastServerUpdate: category.lastServerUpdate, removed: category.removed)
    }

    // Updates self and its dependencies with category, the references to the dependencies (uuid) are not changed
    // In category we don't need this now as it doesn't have dependencies to other models, but it may in the future, in which case we would just have to change the implementation of this method + this way it's consistent with other models that also have this method.
    public func updateWithoutChangingReferences(_ category: ProductCategory) -> ProductCategory {
        return update(category)
    }
}
