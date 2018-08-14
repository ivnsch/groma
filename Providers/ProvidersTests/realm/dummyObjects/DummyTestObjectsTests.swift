//
//  DummyTestObjectsTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 14.08.18.
//

import XCTest
import RealmSwift
@testable import Providers

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
}
