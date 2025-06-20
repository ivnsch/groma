//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ListItemsTests: RealmTestCase {

    func testDeleteListItem() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2ListItems(realm: realm, status: .todo)

        // Get dependency from object before it's invalidated, otherwise we get object invalidated error
        let obj1Product = obj1.product

        // Test
        let deleteResult = DBProv.listItemProvider.deleteSync(indexPath: IndexPath(row: 0, section: 0),
                                           status: .todo,
                                           list: obj1.list,
                                           realmData: RealmData(realm: realm, tokens: [])
        )

        XCTAssertNotNil(deleteResult)
        XCTAssertTrue(deleteResult!.deletedSection)

        let resultObjects = realm.objects(ListItem.self)
        XCTAssertEqual(resultObjects.count, 1)
        EqualityTests.equals(obj1: resultObjects[0], obj2: obj2, compareLists: true)

        // Check that section of first item was deleted, since it's not empty
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

        // Check that all the dependencies are still there
        let resultStoreProducts = realm.objects(StoreProduct.self)
        XCTAssert(resultStoreProducts.count == 2)
        EqualityTests.equals(obj1: resultStoreProducts[0], obj2: obj1Product)
        EqualityTests.equals(obj1: resultStoreProducts[1], obj2: obj2.product)

        let resultQuantifiableProducts = realm.objects(QuantifiableProduct.self)
        XCTAssert(resultQuantifiableProducts.count == 2)
        EqualityTests.equals(obj1: resultQuantifiableProducts[0], obj2: obj1Product.product)
        EqualityTests.equals(obj1: resultQuantifiableProducts[1], obj2: obj2.product.product)

        let resultProducts = realm.objects(Product.self)
        XCTAssert(resultProducts.count == 2)
        EqualityTests.equals(obj1: resultProducts[0], obj2: obj1Product.product.product)
        EqualityTests.equals(obj1: resultProducts[1], obj2: obj2.product.product.product)

        let resultItems = realm.objects(Item.self)
        XCTAssert(resultItems.count == 2)
        EqualityTests.equals(obj1: resultItems[0], obj2: obj1Product.product.product.item)
        EqualityTests.equals(obj1: resultItems[1], obj2: obj2.product.product.product.item)

        let resultCategories = realm.objects(ProductCategory.self)
        XCTAssert(resultCategories.count == 1)
        EqualityTests.equals(obj1: resultCategories[0], obj2: obj1Product.product.product.item.category)
        EqualityTests.equals(obj1: resultCategories[0], obj2: obj2.product.product.product.item.category)

        let resultUnits = realm.objects(Unit.self)
        XCTAssert(resultUnits.count == 2)
        EqualityTests.equals(obj1: resultUnits[0], obj2: obj1Product.product.unit)
        EqualityTests.equals(obj1: resultUnits[1], obj2: obj2.product.product.unit)

        // TODO base quantities?
    }
}
