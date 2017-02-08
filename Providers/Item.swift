//
//  Item.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import UIKit
import RealmSwift

public class Item: Object, Identifiable {

    public dynamic var uuid: String = ""
    public dynamic var name: String = ""
    public dynamic var categoryOpt: ProductCategory? = ProductCategory()
    public dynamic var fav: Int = 0
    
    
    public var category: ProductCategory {
        get {
            return categoryOpt ?? ProductCategory()
        }
        set(newCategory) {
            categoryOpt = newCategory
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["category"]
    }
    
    public convenience init(uuid: String, name: String, category: ProductCategory, fav: Int) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.category = category
        self.fav = fav
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, category: ProductCategory? = nil, fav: Int? = nil) -> Item {
        return Item(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            category: category ?? self.category,
            fav: fav ?? self.fav
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilter(name: String) -> String {
        return "name = '\(name)'"
    }
    
    public func same(_ rhs: Item) -> Bool {
        return uuid == rhs.uuid
    }
    
    // MARK: -
    
    fileprivate func update(_ item: Item, category: ProductCategory) -> Item {
        return copy(name: item.name, category: category, fav: item.fav)
    }
    
    // Updates item's properties that don't belong to its unique with prototype
    public func updateNonUniqueProperties(prototype: ProductPrototype) -> Item {
        let updatedCateogry = category.copy(name: prototype.category, color: prototype.categoryColor)
        return copy(category: updatedCateogry)
    }
    
    // Updates self and its dependencies with category, the references to the dependencies (uuid) are not changed
    // In category we don't need this now as it doesn't have dependencies to other models, but it may in the future, in which case we would just have to change the implementation of this method + this way it's consistent with other models that also have this method.
    public func updateWithoutChangingReferences(_ item: Item) -> Item {
        let updatedCategory = category.updateWithoutChangingReferences(item.category)
        return copy(category: category)
    }
}
