//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ProductFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = Item

    func testUuidFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilter(obj1.uuid)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilter(obj2.uuid)), obj2: obj2)
    }

    func testNameFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterName(obj1.item.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterName(obj2.item.name)), obj2: obj2)
    }

    func testNameUppercaseFilter() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterName(obj1.item.name.uppercased()))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm, specialCharsName: true)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterName(obj1.item.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterName(obj2.item.name)), obj2: obj2)
    }

    func testNameContainsFilterMultipleMatches() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains("ob"))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testNameContainsFilterSingleMatch() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains("obj1"))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testNameContainsUppercaseFilter() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains(obj1.item.name.uppercased()))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testNameContainsFilterNoMatches() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains(nonExistentString))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameContainsFilterNoMatchesSpecialCharsQuery() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains(specialCharsTestString))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testNameContainsFilterNoMatchesSpecialChars() {
        // Prepare
        realm.beginWrite()

        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        realm.add(category)

        let obj1 = Product(uuid: uuid(), name: specialCharsTestString, category: category, brand: "brand1", fav: 0, edible: true)
        realm.add(obj1)

        try! realm.commitWrite()

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterNameContains(specialCharsTestString))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterUuids() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids([obj1.uuid, obj2.uuid]))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }

    func testFilterUuidsContainsOnlyOne() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids([obj1.uuid]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testFilterUuidsEmptyArray() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids([]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsContainsNone() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids(["foo", "bar"]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsSpecialCharactersQuery() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids([specialCharsTestString]))
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }

    func testFilterUuidsRepeatedParameters() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterUuids([obj1.uuid, obj1.uuid]))
        XCTAssert(results.count == 1)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
    }

    func testUuidFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(uuid: nonExistentString))
    }

    func testNameFilterEmpty() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(name: nonExistentString))
    }

    func testUuidFilterInvalidChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(uuid: specialCharsTestString))
    }

    func testNameFilterInvalidChars() {
        // Prepare
        let (_, _, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Item.createFilter(name: specialCharsTestString))
    }

    func testBrandFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterBrand(obj1.brand)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterBrand(obj2.brand)), obj2: obj2)
    }
    // TODO more tests for this filter

    func testUniqueFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let obj1Unique = ProductUnique(name: "obj1", brand: "brand1")
        let obj2Unique = ProductUnique(name: "obj2", brand: "brand2")
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilter(unique: obj1Unique)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilter(unique: obj2Unique)), obj2: obj2)
    }
    // TODO more tests for this filter

    func testNameBrandFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterNameBrand(obj1.item.name, brand: obj1.brand)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Product.createFilterNameBrand(obj2.item.name, brand: obj2.brand)), obj2: obj2)
    }
    // TODO more tests for this filter

    func testBrandContainsFilterMultipleMatches() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterBrandContains("bran"))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }
    // TODO more tests for this filter

    func testCategoryFilter() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterCategoryNameContains("categ"))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }
    // TODO more tests for this filter

    func testCategoryNameContainsFilterMultipleMatches() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert2Products(realm: realm)

        // Test
        let results = realm.objects(Product.self).filter(Product.createFilterCategoryNameContains("categ"))
        XCTAssert(results.count == 2)
        let resultObj1 = results[0]
        EqualityTests.equals(obj1: resultObj1, obj2: obj1)
        let resultObj2 = results[1]
        EqualityTests.equals(obj1: resultObj2, obj2: obj2)
    }
    // TODO more tests for this filter
}
