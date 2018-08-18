//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class SectionsFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = Providers.Section

    // MARK: - Basic

    func testNameFilter() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Section.createFilterWithName(obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Section.createFilterWithName(obj2.name)), obj2: obj2)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo, specialCharsName: true)

        // Test

        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Section.createFilterWithName(obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Section.createFilterWithName(obj2.name)), obj2: obj2)
    }

    func testInventoryFilter() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let results = realm.objects(Section.self).filter(Section.createFilter(inventoryUuid: obj1.list.inventory.uuid))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: resultObj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: resultObj2)
    }

    func testStatusTodoFilter() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let results = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: obj1.list.uuid, status: .todo))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: resultObj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: resultObj2)

        let doneResults = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: obj1.list.uuid, status: .done))
        XCTAssertEqual(doneResults.count, 0)
    }

    func testStatusDoneFilter() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .done)

        // Test
        let results = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: obj1.list.uuid, status: .done))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: resultObj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: resultObj2)

        let todoResults = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: obj1.list.uuid, status: .todo))
        XCTAssertEqual(todoResults.count, 0)
    }

    func testStatusNonExistentListFilter() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let results = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: nonExistentString, status: .todo))
        XCTAssertEqual(results.count, 0)
    }

    func testUniqueFilter() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .done)

        // Test
        let results = realm.objects(Section.self).filter(Section.createFilter(unique: obj1.unique))
        XCTAssertEqual(results.count, 1)
        EqualityTests.equals(obj1: results[0], obj2: obj1)
    }

    func testUniqueFilterManual() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let unique = SectionUnique(name: "obj1", listUuid: obj1.list.uuid, status: .todo)
        let results = realm.objects(Section.self).filter(Section.createFilter(unique: unique))
        XCTAssertEqual(results.count, 1)
        EqualityTests.equals(obj1: results[0], obj2: obj1)
    }

    // TODO more tests

    // MARK: -

    func testNameFilterEmpty() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        testEmptyOrInvalidResults(filter: Section.createFilterWithName(nonExistentString))
    }

    func testNameFilterSpecialChars() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        testEmptyOrInvalidResults(filter: Section.createFilterWithName(specialCharsTestString))
    }
}
