//
//  ProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

class ProductCategory: DBSyncable, Identifiable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"

    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    var color: UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setColor(_ bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }

    convenience init(uuid: String, name: String, color: UIColor, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init(uuid: uuid, name: name, color: color.hexStr, lastUpdate: lastUpdate, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    convenience init(uuid: String, name: String, color: String, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.bgColorHex = color
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, lastUpdate: Date? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductCategory {
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
        item.setColor(color)
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
        DBProviders.productCategoryProvider.removeCategoryDependenciesSync(realm, categoryUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    // MARK: -
    
    func same(_ rhs: ProductCategory) -> Bool {
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
    func updateWithoutChangingReferences(_ category: ProductCategory) -> ProductCategory {
        return update(category)
    }
}

//
//import Foundation
//
//class ProductCategory: Equatable, Identifiable, CustomDebugStringConvertible {
//    let uuid: String
//    let name: String
//    let color: UIColor
//    
//    //////////////////////////////////////////////
//    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
//    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
//    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
//    let lastServerUpdate: Int64?
//    let removed: Bool
//    //////////////////////////////////////////////
//    
//    init(uuid: String, name: String, color: UIColor, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        self.uuid = uuid
//        self.name = name
//        self.color = color
//        
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
//    }
//    
//    fileprivate var shortDescription: String {
//        return "{\(type(of: self)) name: \(name)}"
//    }
//    
//    fileprivate var longDescription: String {
//        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
//    }
//    
//    var debugDescription: String {
//        return shortDescription
//    }
//    
//    var hashValue: Int {
//        return self.uuid.hashValue
//    }
//    
//    func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> ProductCategory {
//        return ProductCategory(
//            uuid: uuid ?? self.uuid,
//            name: name ?? self.name,
//            color: color ?? self.color,
//            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
//            removed: removed ?? self.removed
//        )
//    }
//    
//    func same(_ rhs: ProductCategory) -> Bool {
//        return uuid == rhs.uuid
//    }
//    
//    func equalsExcludingSyncAttributes(_ rhs: ProductCategory) -> Bool {
//        return uuid == rhs.uuid && name == rhs.name && color == rhs.color
//    }
//    
//    fileprivate func update(_ category: ProductCategory) -> ProductCategory {
//        return copy(name: category.name, color: category.color, lastServerUpdate: category.lastServerUpdate, removed: category.removed)
//    }
//    
//    // Updates self and its dependencies with category, the references to the dependencies (uuid) are not changed
//    // In category we don't need this now as it doesn't have dependencies to other models, but it may in the future, in which case we would just have to change the implementation of this method + this way it's consistent with other models that also have this method.
//    func updateWithoutChangingReferences(_ category: ProductCategory) -> ProductCategory {
//        return update(category)
//    }
//}
//
//func ==(lhs: ProductCategory, rhs: ProductCategory) -> Bool {
//    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
//}
