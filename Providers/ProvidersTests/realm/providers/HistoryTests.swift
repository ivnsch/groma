//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class HistoryTests: RealmTestCase {

    fileprivate let provider = RealmHistoryProviderSync()

    func testAddHistoryItemWithAddingManuallyDependencies() {

        realm.beginWrite()

        // Prepare
        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        let item1 = Item(uuid: uuid(), name: "item1", category: category, fav: 0, edible: true)
        realm.add(item1)
        let product = Product(uuid: uuid(), item: item1, brand: "brand1", fav: 0)
        realm.add(product)
        let unit = Providers.Unit(uuid: uuid(), name: "unit1", id: .can, buyable: true)
        realm.add(unit)
        let quantifiableProduct = QuantifiableProduct(uuid: uuid(), baseQuantity: 1, secondBaseQuantity: 1, unit: unit, product: product, fav: 0)
        realm.add(quantifiableProduct)
        let obj = HistoryItem(uuid: uuid(), inventory: inventory, product: quantifiableProduct, addedDate: Date().toMillis(), quantity: 1, user: DBSharedUser(email: "foo1@bar.com"), paidPrice: 1)

        try! realm.commitWrite()

        // Test
        let success = provider.add(historyItem: obj)
        XCTAssertTrue(success)
        let results = provider.loadAllHistoryItems()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj)
    }

    func testAddHistoryItemWithoutAddingManuallyDependencies() {
        // Prepare
        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        let category = ProductCategory(uuid: uuid(), name: "category", color: UIColor.red)
        let item1 = Item(uuid: uuid(), name: "item1", category: category, fav: 0, edible: true)
        let product = Product(uuid: uuid(), item: item1, brand: "brand1", fav: 0)
        let unit = Providers.Unit(uuid: uuid(), name: "unit1", id: .can, buyable: true)
        let quantifiableProduct = QuantifiableProduct(uuid: uuid(), baseQuantity: 1, secondBaseQuantity: 1, unit: unit, product: product, fav: 0)
        let obj = HistoryItem(uuid: uuid(), inventory: inventory, product: quantifiableProduct, addedDate: Date().toMillis(), quantity: 1, user: DBSharedUser(email: "foo1@bar.com"), paidPrice: 1)

        // Test
        let success = provider.add(historyItem: obj)
        XCTAssertTrue(success)
        let results = provider.loadAllHistoryItems()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj)
    }


    func testLoadSortedByDateInDescendingOrder() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let results = provider.loadHistoryItems(inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 3)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
        EqualityTests.equals(obj1: results![2], obj2: obj3)

        let sortedInput = [obj1, obj2, obj3].sorted { (obj1, obj2) -> Bool in
            obj1.addedDate > obj2.addedDate
        }
        XCTAssertGreaterThan(sortedInput[0].addedDate, sortedInput[1].addedDate)
        XCTAssertGreaterThan(sortedInput[1].addedDate, sortedInput[2].addedDate)

        EqualityTests.equals(arr1: results!.toArray(), arr2: sortedInput)
    }

    func testLoadWithStartDate() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let results = provider.loadHistoryItems(startDate: obj2.addedDate, inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
    }

    /// Same as testLoadWithStartDate but using the start date of first item instead of second
    func testLoadWithStartDate2() {
        // Prepare
        let (obj1, _, _) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let results = provider.loadHistoryItems(startDate: obj1.addedDate, inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
    }

    func testLoadWithProductNameAndStartDate() {
        // Prepare
        let (obj1, obj2, _) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let results = provider.loadHistoryItems("item1", startDate: obj2.addedDate, inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
    }

    func testLoadAllHistoryItems() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let results = provider.loadAllHistoryItems()

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 3)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
        EqualityTests.equals(obj1: results![2], obj2: obj3)
    }

    func testLoadWithMonthYear() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let pastMonthYear = Date().inMonths(-1).dayMonthYear

        let results = provider.loadHistoryItems(MonthYear(month: pastMonthYear.month, year: pastMonthYear.year), inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
    }

    func testLoadWithStartAndEndDate() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Debug
        print("obj1 added date: \(Date.from(millis: obj1.addedDate)), millis: \(obj1.addedDate)")
        print("obj2 added date: \(Date.from(millis: obj2.addedDate)), millis: \(obj2.addedDate)")
        print("obj3 added date: \(Date.from(millis: obj3.addedDate)), millis: \(obj3.addedDate)")

        // Test
        let startDate = Date().inMonths(-4) // Note: -4 because -3 is not enough - since we use millis - between adding the item with -3 and here a few millis have passed, thus the -3 here will not include the oldest item.
        let endDate = Date().inMonths(-1)

        print("startDate: \(startDate), start date millis: \(startDate.toMillis()), endDate: \(endDate), end date millis: \(endDate.toMillis())")

        let results = provider.loadHistoryItems(startDate.toMillis(), endDate: endDate.toMillis(), inventory: obj1.inventory)

        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 3)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
        EqualityTests.equals(obj1: results![2], obj2: obj3)
    }

    func testLoadGroups() {
        // Prepare
        let (obj1, obj2, obj3) = DummyTestObjects.insert3HistoryItems(realm: realm)

        // Test
        let groups = provider.loadHistoryItemsGroups(NSRange(location: 0, length: 10), inventory: obj1.inventory)

        XCTAssertEqual(groups.count, 3)

        // History provider strips seconds when grouping, so have to strip from input too
        XCTAssertEqual(groups[0].date, Date.from(millis: obj1.addedDate).dateWithZeroSeconds())
        XCTAssertEqual(groups[1].date, Date.from(millis: obj2.addedDate).dateWithZeroSeconds())
        XCTAssertEqual(groups[2].date, Date.from(millis: obj3.addedDate).dateWithZeroSeconds())

        EqualityTests.equals(obj1: groups[0].user, obj2: obj1.user)
        EqualityTests.equals(obj1: groups[1].user, obj2: obj2.user)
        EqualityTests.equals(obj1: groups[2].user, obj2: obj3.user)

        XCTAssertEqual(groups[0].historyItems.count, 1)
        XCTAssertEqual(groups[1].historyItems.count, 1)
        XCTAssertEqual(groups[2].historyItems.count, 1)

        EqualityTests.equals(obj1: groups[0].historyItems[0], obj2: obj1)
        EqualityTests.equals(obj1: groups[1].historyItems[0], obj2: obj2)
        EqualityTests.equals(obj1: groups[2].historyItems[0], obj2: obj3)
    }

    func testRemoveHistoryItem() {
        // TODO
    }

    // TODO test rest of methods
}
