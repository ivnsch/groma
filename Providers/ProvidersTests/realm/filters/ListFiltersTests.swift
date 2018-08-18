//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ListFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = Providers.List

    // MARK: - Basic

    func testUuidFilter() {
        // Prepare
        let (_, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(uuid: obj1.uuid)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(uuid: obj2.uuid)), obj2: obj2)
    }

    func testNameFilter() {
        // Prepare
        let (_, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(name: obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(name: obj2.name)), obj2: obj2)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (_, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm, specialCharsName: true)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(name: obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Providers.List.createFilter(name: obj2.name)), obj2: obj2)
    }

    func testInventoryFilter() {
        // Prepare
        let (inventory, obj1, obj2) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        let results = realm.objects(List.self).filter(Providers.List.createInventoryFilter(inventory.uuid))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: resultObj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: resultObj2)
    }

    // MARK: -

    func testUuidFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createInventoryFilter(nonExistentString))
    }

    func testNameFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createInventoryFilter(nonExistentString))
    }

    func testInventoryFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createInventoryFilter(nonExistentString))
    }

    func testUuidFilterSpecialChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createFilter(uuid: specialCharsTestString))
    }

    func testNameFilterSpecialChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createFilter(uuid: specialCharsTestString))
    }

    func testInventoryFilterSpecialChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insertInventoryAnd2Lists(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Providers.List.createInventoryFilter(specialCharsTestString))
    }
}
