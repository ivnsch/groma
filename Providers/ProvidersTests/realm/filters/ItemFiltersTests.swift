//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ItemFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = Item

    func testUuidFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(uuid: obj1.uuid)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(uuid: obj2.uuid)), obj2: obj2)
    }

    func testNameFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(name: obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(name: obj2.name)), obj2: obj2)
    }

    func testNameUppercaseFilter() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(name: obj1.name.uppercased()))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm, specialCharsName: true)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(name: obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Item.createFilter(name: obj2.name)), obj2: obj2)
    }

    func testNameContainsFilterMultipleMatches() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains("ob"))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testNameContainsFilterSingleMatch() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains("obj1"))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testNameContainsUppercaseFilter() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains(obj1.name.uppercased()))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testNameContainsFilterNoMatches() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains(nonExistentString))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameContainsFilterNoMatchesSpecialCharsQuery() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains(specialCharsTestString))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameContainsFilterNoMatchesSpecialChars() {
        // Prepare
        testRealm.beginWrite()

        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        testRealm.add(category)

        let obj1 = Item(uuid: uuid(), name: specialCharsTestString, category: category, fav: 0, edible: true)
        testRealm.add(obj1)

        try! testRealm.commitWrite()

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterNameContains(specialCharsTestString))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterUuids() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids([obj1.uuid, obj2.uuid]))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterUuidsContainsOnlyOne() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids([obj1.uuid]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterUuidsEmptyArray() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids([]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsContainsNone() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids(["foo", "bar"]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsSpecialCharactersQuery() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids([specialCharsTestString]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsRepeatedParameters() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilterUuids([obj1.uuid, obj1.uuid]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterNames() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: [obj1.name, obj2.name]))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterNamesContainsOnlyOne() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: [obj1.name]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterNamesEmptyArray() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: []))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterNamesContainsNone() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: ["foo", "bar"]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterNamesRepeatedParameters() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: [obj1.name, obj1.name]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterNamesSpecialCharactersQuery() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: [specialCharsTestString]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterNamesSpecialCharacters() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm, specialCharsName: true)

        // Test
        let results = testRealm.objects(Item.self).filter(Item.createFilter(names: [obj1.name, obj2.name]))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testUuidFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(uuid: nonExistentString))
    }

    func testNameFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(name: nonExistentString))
    }

    func testUuidFilterInvalidChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(uuid: specialCharsTestString))
    }

    func testNameFilterInvalidChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(name: specialCharsTestString))
    }

    func testFilterEdible() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm, specialCharsName: true)

        // Test
        let results1 = testRealm.objects(Item.self).filter(Item.createFilter(edible: true))
        XCTAssert(results1.count == 1)
        let resultObj1 = results1[0]
        XCTAssertTrue(resultObj1.edible)
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)

        let results2 = testRealm.objects(Item.self).filter(Item.createFilter(edible: false))
        XCTAssert(results2.count == 1)
        let resultObj2 = results2[0]
        XCTAssertFalse(resultObj2.edible)
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterNameContainsAndEdible() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results1 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible("obj", edible: true))
        XCTAssert(results1.count == 1)
        let resultObj1 = results1[0]
        XCTAssertTrue(resultObj1.edible)
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)

        let results2 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible("obj", edible: false))
        XCTAssert(results2.count == 1)
        let resultObj2 = results2[0]
        XCTAssertFalse(resultObj2.edible)
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterNameContainsPerfectMatchAndEdible() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results1 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible("obj1", edible: true))
        XCTAssert(results1.count == 1)
        let resultObj1 = results1[0]
        XCTAssertTrue(resultObj1.edible)
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)

        let results2 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible("obj2", edible: false))
        XCTAssert(results2.count == 1)
        let resultObj2 = results2[0]
        XCTAssertFalse(resultObj2.edible)
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterNameContainsAndEdibleEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Items(realm: testRealm)

        // Test
        let results1 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible(nonExistentString, edible: true))
        XCTAssert(results1.count == 0)
        XCTAssert(results1.isEmpty)

        let results2 = testRealm.objects(Item.self).filter(Item.createFilterNameContainsAndEdible(nonExistentString, edible: false))
        XCTAssert(results2.count == 0)
        XCTAssert(results2.isEmpty)
    }
}
