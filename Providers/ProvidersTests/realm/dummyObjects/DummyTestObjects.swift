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
* IMPORTANT: Tests rely on values (names, indexes, dates, attributes in general). assigned here. Don't change!
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

        let inventory1 = DBInventory(uuid: uuid(), name: name(specialCharsName, 1), users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory1)

        let inventory2 = DBInventory(uuid: uuid(), name: name(specialCharsName, 2), users: [], bgColor: UIColor.black, order: 1)
        realm.add(inventory2)

        try! realm.commitWrite()

        return (inventory1: inventory1, inventory2: inventory2)
    }

    static func insert2Recipes(realm: Realm, specialCharsName: Bool = false) -> Insert2RecipesResult {
        realm.beginWrite()

        let recipe1 = Recipe(uuid: uuid(), name: name(specialCharsName, 1), color: UIColor.black, fav: 0, text: "text1", spans: Array<TextSpan>())
        realm.add(recipe1)

        let recipe2 = Recipe(uuid: uuid(), name: name(specialCharsName, 2), color: UIColor.black, fav: 0, text: "text2", spans: Array<TextSpan>())
        realm.add(recipe2)

        try! realm.commitWrite()

        return (recipe1: recipe1, recipe2: recipe2)
    }

    static func insertInventoryAnd2Lists(realm: Realm, specialCharsName: Bool = false) -> InsertInventoryAnd2ListsResult {
        realm.beginWrite()

        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)

        let firstListUuid = uuid()
        let secondListUuid = uuid()
        let list1 = List(uuid: firstListUuid, name: name(specialCharsName, 1), users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store1")
        let list2 = List(uuid: secondListUuid, name: name(specialCharsName, 2), users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store2")
        realm.add(list1)
        realm.add(list2)
        
        try! realm.commitWrite()

        return (inventory: inventory, list1: list1, list2: list2)
    }

    static func insert3HistoryItems(realm: Realm, specialCharsName: Bool = false) -> Insert3HistoryItemsResult {
        realm.beginWrite()

        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)

        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        realm.add(category)

        let item1 = Item(uuid: uuid(), name: "item1", category: category, fav: 0, edible: true)
        realm.add(item1)
        let item2 = Item(uuid: uuid(), name: "item2", category: category, fav: 0, edible: false)
        realm.add(item2)

        let product1 = Product(uuid: uuid(), item: item1, brand: "brand1", fav: 0)
        realm.add(product1)
        let product2 = Product(uuid: uuid(), item: item2, brand: "brand2", fav: 0)
        realm.add(product2)

        let unit1 = Providers.Unit(uuid: uuid(), name: "unit1", id: .can, buyable: true)
        realm.add(unit1)
        let unit2 = Providers.Unit(uuid: uuid(), name: "unit2", id: .clove, buyable: false)
        realm.add(unit2)

        let quantifiableProduct1 = QuantifiableProduct(uuid: uuid(), baseQuantity: 1, secondBaseQuantity: 1, unit: unit1, product: product1, fav: 0)
        realm.add(quantifiableProduct1)
        let quantifiableProduct2 = QuantifiableProduct(uuid: uuid(), baseQuantity: 2, secondBaseQuantity: 2, unit: unit2, product: product2, fav: 0)
        realm.add(quantifiableProduct2)

        let historyItem1 = HistoryItem(uuid: uuid(), inventory: inventory, product: quantifiableProduct1, addedDate: Date().inMonths(-1).toMillis(), quantity: 1, user: DBSharedUser(email: "foo1@bar.com"), paidPrice: 1)
        realm.add(historyItem1)
        let historyItem2 = HistoryItem(uuid: uuid(), inventory: inventory, product: quantifiableProduct2, addedDate: Date().inMonths(-2).toMillis(), quantity: 2, user: DBSharedUser(email: "foo2@bar.com"), paidPrice: 2)
        realm.add(historyItem2)
        let historyItem3 = HistoryItem(uuid: uuid(), inventory: inventory, product: quantifiableProduct2, addedDate: Date().inMonths(-3).toMillis(), quantity: 3, user: DBSharedUser(email: "foo3@bar.com"), paidPrice: 3)
        realm.add(historyItem3)

        try! realm.commitWrite()

        return (obj1: historyItem1, obj2: historyItem2, obj3: historyItem3)
    }

    /**
    * Non-special char name is "obj" + index, e.g. obj1, obj2, obj3
    * Special char is the specialCharsTestString global constant + index
    */
    fileprivate static func name(_ specialChars: Bool, _ index: Int) -> String {
        return specialChars ? "\(specialCharsTestString)\(index)" : "obj\(index)"
    }
}

typealias Insert3HistoryItemsResult = (
    obj1: HistoryItem,
    obj2: HistoryItem,
    obj3: HistoryItem
)

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
