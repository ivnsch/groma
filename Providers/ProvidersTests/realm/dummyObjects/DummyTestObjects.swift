//
//  DummyTestObjects.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 14.08.18.
//

import UIKit
import RealmSwift
@testable import Providers

/**
* IMPORTANT: Tests rely on values (names, indexes, attributes in general). assigned here. Don't change!
*/
class DummyTestObjects {

    static func insert2Products(realm: Realm, specialCharsName: Bool = false) -> Insert2ProductsResult {
        realm.beginWrite()

        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        realm.add(category)

        let obj1 = Product(uuid: uuid(), name: name(specialCharsName, 1), category: category, brand: "brand1", fav: 0, edible: true)
        let obj2 = Product(uuid: uuid(), name: name(specialCharsName, 2), category: category, brand: "brand2", fav: 0, edible: true)
        realm.add(obj1)
        realm.add(obj2)

        try! realm.commitWrite()

        return (obj1: obj1, obj2: obj2, category: category)
    }

    static func insert2Items(realm: Realm, specialCharsName: Bool = false) -> Insert2ItemsResult {
        realm.beginWrite()

        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        realm.add(category)

        let obj1 = Item(uuid: uuid(), name: name(specialCharsName, 1), category: category, fav: 0, edible: true)
        let obj2 = Item(uuid: uuid(), name: name(specialCharsName, 2), category: category, fav: 0, edible: false)
        realm.add(obj1)
        realm.add(obj2)

        try! realm.commitWrite()

        return (obj1: obj1, obj2: obj2, category: category)
    }

    static func insert2Inventories(realm: Realm, specialCharsName: Bool = false) -> Insert2InventoriesResult {
        realm.beginWrite()

        let inventory1 = DBInventory(uuid: UUID().uuidString, name: name(specialCharsName, 1), users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory1)

        let inventory2 = DBInventory(uuid: UUID().uuidString, name: name(specialCharsName, 2), users: [], bgColor: UIColor.black, order: 1)
        realm.add(inventory2)

        try! realm.commitWrite()

        return (inventory1: inventory1, inventory2: inventory2)
    }

    static func insert2Recipes(realm: Realm, specialCharsName: Bool = false) -> Insert2RecipesResult {
        realm.beginWrite()

        let recipe1 = Recipe(uuid: UUID().uuidString, name: name(specialCharsName, 1), color: UIColor.black, fav: 0, text: "text1", spans: Array<TextSpan>())
        realm.add(recipe1)

        let recipe2 = Recipe(uuid: UUID().uuidString, name: name(specialCharsName, 2), color: UIColor.black, fav: 0, text: "text2", spans: Array<TextSpan>())
        realm.add(recipe2)

        try! realm.commitWrite()

        return (recipe1: recipe1, recipe2: recipe2)
    }

    static func insertInventoryAnd2Lists(realm: Realm, specialCharsName: Bool = false) -> InsertInventoryAnd2ListsResult {
        realm.beginWrite()

        let inventory = DBInventory(uuid: UUID().uuidString, name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)

        let firstListUuid = UUID().uuidString
        let secondListUuid = UUID().uuidString
        let list1 = List(uuid: firstListUuid, name: name(specialCharsName, 1), users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store1")
        let list2 = List(uuid: secondListUuid, name: name(specialCharsName, 2), users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store2")
        realm.add(list1)
        realm.add(list2)
        
        try! realm.commitWrite()

        return (inventory: inventory, list1: list1, list2: list2)
    }

    /**
    * Non-special char name is "obj" + index, e.g. obj1, obj2, obj3
    * Special char is the specialCharsTestString global constant + index
    */
    fileprivate static func name(_ specialChars: Bool, _ index: Int) -> String {
        return specialChars ? "\(specialCharsTestString)\(index)" : "obj\(index)"
    }
}

typealias Insert2ItemsResult = (
    obj1: Item,
    obj2: Item,
    category: ProductCategory
)

typealias Insert2ProductsResult = (
    obj1: Product,
    obj2: Product,
    category: ProductCategory
)

typealias Insert2InventoriesResult = (
    inventory1: DBInventory,
    inventory2: DBInventory
)

typealias Insert2RecipesResult = (
    recipe1: Recipe,
    recipe2: Recipe
)

typealias InsertInventoryAnd2ListsResult = (
    inventory: DBInventory,
    list1: Providers.List,
    list2: Providers.List
)
