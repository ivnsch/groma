//
//  ItemsTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 02.09.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ItemsTests: RealmTestCase {

    func testCascadeDeleteItemAfterInsertListItems() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2ListItems(realm: realm, status: .todo)

        // Get dependency from object before it's invalidated, otherwise we get object invalidated error
        let obj1Unit = obj1.product.product.unit

        // Test
        let deleteItemSuccess = DBProv.itemProvider.deleteSync(uuid: obj1.product.product.product.item.uuid, realmData: RealmData(realm: realm, tokens: []))

        XCTAssertTrue(deleteItemSuccess)

        let resultObjects = realm.objects(ListItem.self)
        XCTAssertEqual(resultObjects.count, 1)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj2, compareLists: true)

        // Check that section of first list item was deleted, since it's not empty
        let resultSections = realm.objects(Section.self)
        XCTAssertEqual(resultSections.count, 1)
        EqualityTests.equals(obj1: resultSections[0], obj2: obj2.section)

        // Check that list state is ok
        let resultList = realm.objects(List.self)
        XCTAssertEqual(resultList.count, 1)
        EqualityTests.equals(obj1: resultList[0], obj2: obj2.list)
        XCTAssertEqual(resultList[0].todoSections.count, 1)
        EqualityTests.equals(obj1: resultList[0].todoSections[0], obj2: obj2.section)
        XCTAssertEqual(resultList[0].todoSections[0].listItems.count, 1)
        EqualityTests.equals(obj1: resultList[0].todoSections[0].listItems[0], obj2: obj2, compareLists: true)
        XCTAssertEqual(resultList[0].doneListItems.count, 0)
        XCTAssertEqual(resultList[0].stashListItems.count, 0)

        let resultStoreProducts = realm.objects(StoreProduct.self)
        XCTAssert(resultStoreProducts.count == 1)
        EqualityTests.equals(obj1: resultStoreProducts[0], obj2: obj2.product)

        let resultQuantifiableProducts = realm.objects(QuantifiableProduct.self)
        XCTAssert(resultQuantifiableProducts.count == 1)
        EqualityTests.equals(obj1: resultQuantifiableProducts[0], obj2: obj2.product.product)

        let resultProducts = realm.objects(Product.self)
        XCTAssert(resultProducts.count == 1)
        EqualityTests.equals(obj1: resultProducts[0], obj2: obj2.product.product.product)

        let resultItems = realm.objects(Item.self)
        XCTAssert(resultItems.count == 1)
        EqualityTests.equals(obj1: resultItems[0], obj2: obj2.product.product.product.item)

        let resultCategories = realm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: obj2.product.product.product.item.category)

        // Unit don't reference items, so not affected by cascade delete
        let resultUnits = realm.objects(Unit.self)
        XCTAssert(resultUnits.count == 2)
        EqualityTests.equals(obj1: resultUnits[0], obj2: obj1Unit)
        EqualityTests.equals(obj1: resultUnits[1], obj2: obj2.product.product.unit)

        // TODO base quantities?
    }
}
