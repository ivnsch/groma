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

    func testInsert2Items() {
        // Prepare
        let (obj1, obj2, category) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let resultObjects = testRealm.objects(Item.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultCategories = testRealm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: category)
    }

    func testInsert2Products() {
        // Prepare
        let (obj1, obj2, category) = DummyTestObjects.insert2Products(realm: testRealm)

        // Test
        let resultObjects = testRealm.objects(Product.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultCategories = testRealm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: category)
    }

    func testInsert2Inventories() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        let resultInventories = testRealm.objects(DBInventory.self)
        XCTAssert(resultInventories.count == 2)
        EqualityTests.equals(obj1: resultInventories[0], obj2: obj1)
        EqualityTests.equals(obj1: resultInventories[1], obj2: obj2)
    }

    func testInsertInventoryAnd2Lists() {
        // Prepare
        let (inventory, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: testRealm)

        // Test
        let resultObjects = testRealm.objects(List.self)
        XCTAssert(resultObjects.count == 2)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)

        let resultInventories = testRealm.objects(DBInventory.self)
        XCTAssert(resultInventories.count == 1)
        EqualityTests.equals(obj1: resultInventories[0], obj2: inventory)
    }

    func testInsert2Recipes() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Recipes(realm: testRealm)

        // Test
        let resultRecipes = testRealm.objects(Recipe.self)
        XCTAssert(resultRecipes.count == 2)
        EqualityTests.equals(obj1: resultRecipes[0], obj2: obj1)
        EqualityTests.equals(obj1: resultRecipes[1], obj2: obj2)
    }

    func testInsert3HistoryItems() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: testRealm)

        // Test
        let resultObjects = testRealm.objects(HistoryItem.self)
        XCTAssertEqual(resultObjects.count, 3)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj1)
        EqualityTests.equals(obj1: resultObjects[1], obj2: obj2)
        EqualityTests.equals(obj1: resultObjects[2], obj2: obj3)

        let resultQuantifiableProducts = testRealm.objects(QuantifiableProduct.self)
        XCTAssertEqual(resultQuantifiableProducts.count, 2)
        EqualityTests.equals(obj1: resultQuantifiableProducts[0], obj2: obj1.product)
        EqualityTests.equals(obj1: resultQuantifiableProducts[1], obj2: obj2.product)

        let resultProducts = testRealm.objects(Product.self)
        XCTAssertEqual(resultProducts.count, 2)
        EqualityTests.equals(obj1: resultProducts[0], obj2: obj1.product.product)
        EqualityTests.equals(obj1: resultProducts[1], obj2: obj2.product.product)

        let resultItems = testRealm.objects(Item.self)
        XCTAssertEqual(resultItems.count, 2)
        EqualityTests.equals(obj1: resultItems[0], obj2: obj1.product.product.item)
        EqualityTests.equals(obj1: resultItems[1], obj2: obj2.product.product.item)

        let resultProductCategories = testRealm.objects(ProductCategory.self)
        XCTAssertEqual(resultProductCategories.count, 1)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj1.product.product.item.category)
        EqualityTests.equals(obj1: resultProductCategories[0], obj2: obj2.product.product.item.category)

        let resultSharedUsers = testRealm.objects(DBSharedUser.self)
        XCTAssertEqual(resultSharedUsers.count, 3)
        EqualityTests.equals(obj1: resultSharedUsers[0], obj2: obj1.user)
        EqualityTests.equals(obj1: resultSharedUsers[1], obj2: obj2.user)
        EqualityTests.equals(obj1: resultSharedUsers[2], obj2: obj3.user)

        let resultUnits = testRealm.objects(Unit.self)
        XCTAssertEqual(resultUnits.count, 2)
        EqualityTests.equals(obj1: resultUnits[0], obj2: obj1.product.unit)
        EqualityTests.equals(obj1: resultUnits[1], obj2: obj2.product.unit)
    }
}
