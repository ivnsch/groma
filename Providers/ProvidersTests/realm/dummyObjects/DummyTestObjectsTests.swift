//
//  DummyTestObjectsTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 14.08.18.
//

import XCTest
import RealmSwift
@testable import Providers

// TODO don't assume sorted results - these are not lists just realm results and sorting isn't guaranteed (though currently it's always working)
// sort both input and results to compare
class DummyTestObjectsTests: RealmTestCase {

    func testInsert2TodoListItems() {
        testInsert2ListItems(status: .todo)
    }

    func testInsert2DoneListItems() {
        testInsert2ListItems(status: .done)
    }

    func testInsert2StashListItems() {
        testInsert2ListItems(status: .stash)
    }

    private func testInsert2ListItems(status: ListItemStatus) {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2ListItems(realm: realm, status: status)

        // Test
        let resultObjects = realm.objects(ListItem.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1, compareLists: true)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2, compareLists: true)

        let resultStoreProducts = realm.objects(StoreProduct.self)
        XCTAssertEqual(resultStoreProducts.count, 2)
        EqualityTests.equals(obj1: resultStoreProducts[0], obj2: obj1.product)
        EqualityTests.equals(obj1: resultStoreProducts[1], obj2: obj2.product)

        let resultQuantifiableProducts = realm.objects(QuantifiableProduct.self)
        XCTAssertEqual(resultQuantifiableProducts.count, 2)
        EqualityTests.equals(obj1: resultQuantifiableProducts[0], obj2: obj1.product.product)
        EqualityTests.equals(obj1: resultQuantifiableProducts[1], obj2: obj2.product.product)

        let resultProducts = realm.objects(Product.self)
        XCTAssertEqual(resultProducts.count, 2)
        EqualityTests.equals(obj1: resultProducts[0], obj2: obj1.product.product.product)
        EqualityTests.equals(obj1: resultProducts[1], obj2: obj2.product.product.product)

        let resultItems = realm.objects(Item.self)
        XCTAssertEqual(resultItems.count, 2)
        EqualityTests.equals(obj1: resultItems[0], obj2: obj1.product.product.product.item)
        EqualityTests.equals(obj1: resultItems[1], obj2: obj2.product.product.product.item)

        let resultProductCategories = realm.objects(ProductCategory.self)
        XCTAssertEqual(resultProductCategories.count, 1)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj1.product.product.product.item.category)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj2.product.product.product.item.category)

        let resultUnits = realm.objects(Unit.self)
        XCTAssertEqual(resultUnits.count, 2)
        EqualityTests.equals(obj1: resultUnits[0], obj2: obj1.product.product.unit)
        EqualityTests.equals(obj1: resultUnits[1], obj2: obj2.product.product.unit)

        let resultSections = realm.objects(Section.self)
        XCTAssertEqual(resultSections.count, 2)
        EqualityTests.equals(obj1: resultSections[0], obj2: obj1.section)
        EqualityTests.equals(obj1: resultSections[1], obj2: obj2.section)
        XCTAssertEqual(resultSections[0].listItems.count, 1)
        XCTAssertEqual(resultSections[1].listItems.count, 1)
        EqualityTests.equals(obj1: resultSections[0].listItems[0], obj2: obj1, compareLists: true)
        EqualityTests.equals(obj1: resultSections[1].listItems[0], obj2: obj2, compareLists: true)

        let resultLists = realm.objects(List.self)
        XCTAssertEqual(resultLists.count, 1)
        EqualityTests.equals(obj1: resultLists[0], obj2: obj1.list)

        switch status {
        case .todo:
            XCTAssertEqual(resultLists[0].todoSections.count, 2)
            EqualityTests.equals(obj1: resultLists[0].todoSections[0], obj2: obj1.section)
            EqualityTests.equals(obj1: resultLists[0].todoSections[1], obj2: obj2.section)
            EqualityTests.equals(obj1: resultLists[0].todoSections[0].listItems[0], obj2: obj1, compareLists: true)
            EqualityTests.equals(obj1: resultLists[0].todoSections[1].listItems[0], obj2: obj2, compareLists: true)
        case .done:
            XCTAssertEqual(resultLists[0].doneListItems.count, 2)
            EqualityTests.equals(obj1: resultLists[0].doneListItems[0], obj2: obj1, compareLists: true)
            EqualityTests.equals(obj1: resultLists[0].doneListItems[1], obj2: obj2, compareLists: true)
        case .stash:
            XCTAssertEqual(resultLists[0].stashListItems.count, 2)
            EqualityTests.equals(obj1: resultLists[0].stashListItems[0], obj2: obj1, compareLists: true)
            EqualityTests.equals(obj1: resultLists[0].stashListItems[1], obj2: obj2, compareLists: true)
        }

        let resultInventories = realm.objects(DBInventory.self)
        XCTAssertEqual(resultInventories.count, 1)
        EqualityTests.equals(obj1: resultInventories[0], obj2: obj1.list.inventory)
    }

    func testInsert2Items() {
        // Prepare
        let (obj1, obj2, category) = DummyTestObjects.insert2Items(realm: realm)

        // Test
        let resultObjects = realm.objects(Item.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultCategories = realm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: category)
    }

    func testInsert2Categories() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Categories(realm: realm)

        // Test
        let resultObjects = realm.objects(ProductCategory.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)
    }

    func testInsert2Products() {
        // Prepare
        let (obj1, obj2, category) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let resultObjects = realm.objects(Product.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultCategories = realm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: category)
    }

    func testInsert2Inventories() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Inventories(realm: realm)

        // Test
        let resultInventories = realm.objects(DBInventory.self)
        XCTAssert(resultInventories.count == 2)
        EqualityTests.equals(obj1: resultInventories[0], obj2: obj1)
        EqualityTests.equals(obj1: resultInventories[1], obj2: obj2)
    }

    func testInsertInventoryAnd2Lists() {
        // Prepare
        let (inventory, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        let resultObjects = realm.objects(List.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultInventories = realm.objects(DBInventory.self)
        XCTAssert(resultInventories.count == 1)
        EqualityTests.equals(obj1: resultInventories[0], obj2: inventory)
    }

    func testInsert2Recipes() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        let resultRecipes = realm.objects(Recipe.self)
        XCTAssert(resultRecipes.count == 2)
        EqualityTests.equals(obj1: resultRecipes[0], obj2: obj1)
        EqualityTests.equals(obj1: resultRecipes[1], obj2: obj2)
    }

    func testInsert3HistoryItems() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let resultObjects = realm.objects(HistoryItem.self)
        XCTAssertEqual(resultObjects.count, 3)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)
        EqualityTests.equals(obj1: resultObjects[2], obj2: obj3)

        let resultQuantifiableProducts = realm.objects(QuantifiableProduct.self)
        XCTAssertEqual(resultQuantifiableProducts.count, 2)
        EqualityTests.equals(obj1: resultQuantifiableProducts[0], obj2: obj1.product)
        EqualityTests.equals(obj1: resultQuantifiableProducts[1], obj2: obj2.product)

        let resultProducts = realm.objects(Product.self)
        XCTAssertEqual(resultProducts.count, 2)
        EqualityTests.equals(obj1: resultProducts[0], obj2: obj1.product.product)
        EqualityTests.equals(obj1: resultProducts[1], obj2: obj2.product.product)

        let resultItems = realm.objects(Item.self)
        XCTAssertEqual(resultItems.count, 2)
        EqualityTests.equals(obj1: resultItems[0], obj2: obj1.product.product.item)
        EqualityTests.equals(obj1: resultItems[1], obj2: obj2.product.product.item)

        let resultProductCategories = realm.objects(ProductCategory.self)
        XCTAssertEqual(resultProductCategories.count, 1)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj1.product.product.item.category)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj2.product.product.item.category)

        let resultSharedUsers = realm.objects(DBSharedUser.self)
        XCTAssertEqual(resultSharedUsers.count, 3)
        EqualityTests.equals(obj1: resultSharedUsers[0], obj2: obj1.user)
        EqualityTests.equals(obj1: resultSharedUsers[1], obj2: obj2.user)
        EqualityTests.equals(obj1: resultSharedUsers[2], obj2: obj3.user)

        let resultUnits = realm.objects(Unit.self)
        XCTAssertEqual(resultUnits.count, 2)
        EqualityTests.equals(obj1: resultUnits[0], obj2: obj1.product.unit)
        EqualityTests.equals(obj1: resultUnits[1], obj2: obj2.product.unit)
    }

    func testInsert2TodoSections() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let resultObjs = realm.objects(Section.self)
        XCTAssert(resultObjs.count == 2)
        EqualityTests.equals(obj1: resultObjs[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjs[1], obj2: obj2)

        XCTAssertEqual(obj1.list.todoSections.count, 2)
        EqualityTests.equals(obj1: obj1.list.todoSections[0], obj2: obj1)
        EqualityTests.equals(obj1: obj1.list.todoSections[1], obj2: obj2)
    }

    func testInsert2DoneSections() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .done)

        // Test
        let resultObjs = realm.objects(Section.self)
        XCTAssert(resultObjs.count == 2)
        EqualityTests.equals(obj1: resultObjs[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjs[1], obj2: obj2)

        XCTAssertEqual(obj1.list.todoSections.count, 0)
    }
}
