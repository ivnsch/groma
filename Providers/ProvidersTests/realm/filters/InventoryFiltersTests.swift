//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class InventoryFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = DBInventory

    // MARK: - Basic

    func testUuidFilter() {
        // Prepare
        let (inventory1, inventory2) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(uuid: inventory1.uuid)), obj2: inventory1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(uuid: inventory2.uuid)), obj2: inventory2)
    }

    func testNameFilter() {
        // Prepare
        let (inventory1, inventory2) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(name: inventory1.name)), obj2: inventory1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(name: inventory2.name)), obj2: inventory2)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Inventories(realm: testRealm, specialCharsName: true)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(name: obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: DBInventory.createFilter(name: obj2.name)), obj2: obj2)
    }

    // MARK: -

    func testUuidFilterEmpty() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: DBInventory.createFilter(uuid: nonExistentString))
    }

    func testNameFilterEmpty() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: DBInventory.createFilter(name: nonExistentString))
    }

    func testUuidFilterInvalidChars() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: DBInventory.createFilter(uuid: specialCharsTestString))
    }

    func testNameFilterInvalidChars() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Inventories(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: DBInventory.createFilter(name: specialCharsTestString))
    }

}
