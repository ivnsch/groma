//
//  EqualityTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import UIKit
import Providers
import XCTest


class EqualityTests {

    fileprivate func sorted<T: WithUuid>(arr: [T]) -> [T] {
        return arr.sorted(by: { (item1, item2) -> Bool in
            item1.uuid > item2.uuid
        })
    }

    static func equals(arr1: [Providers.Unit], arr2: [Providers.Unit]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [BaseQuantity], arr2: [BaseQuantity]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [DBInventory], arr2: [DBInventory]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(inv1: obj1, inv2: obj2)
        }
    }

    static func equals(arr1: [List], arr2: [List]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(list1: obj1, list2: obj2)
        }
    }

    static func equals(arr1: [Section], arr2: [Section]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(section1: obj1, section2: obj2)
        }
    }

    static func equals(arr1: [ListItem], arr2: [ListItem]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(listItem1: obj1, listItem2: obj2)
        }
    }

    static func equals(arr1: [Item], arr2: [Item]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(item1: obj1, item2: obj2)
        }
    }

    static func equals(arr1: [ProductCategory], arr2: [ProductCategory]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(category1: obj1, category2: obj2)
        }
    }

    static func equals(arr1: [Product], arr2: [Product]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(product1: obj1, product2: obj2)
        }
    }

    static func equals(arr1: [QuantifiableProduct], arr2: [QuantifiableProduct]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(quantifiableProduct1: obj1, quantifiableProduct2: obj2)
        }
    }

    static func equals(arr1: [StoreProduct], arr2: [StoreProduct]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(storeProduct1: obj1, storeProduct2: obj2)
        }
    }

    static func equals(arr1: [DBSharedUser], arr2: [DBSharedUser]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(user1: obj1, user2: obj2)
        }
    }

    static func equals(arr1: [HistoryItem], arr2: [HistoryItem]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(obj1: Providers.Unit, obj2: Providers.Unit) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.id, obj2.id)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.buyable, obj2.buyable)
    }

    static func equals(obj1: BaseQuantity, obj2: BaseQuantity) {
        XCTAssertEqual(obj1.val, obj2.val)
    }

    static func equals(user1: DBSharedUser, user2: DBSharedUser) {
        XCTAssertEqual(user1.email, user2.email)
    }

    static func equals(inv1: DBInventory, inv2: DBInventory) {
        XCTAssertEqual(inv1.uuid, inv2.uuid)
        XCTAssertEqual(inv1.name, inv2.name)
        XCTAssertEqual(inv1.bgColor(), inv2.bgColor())
        XCTAssertEqual(inv1.order, inv2.order)

        equals(arr1: inv1.users.toArray(), arr2: inv2.users.toArray())
    }

    static func equals(list1: List, list2: List) {
        XCTAssertEqual(list1.uuid, list2.uuid)
        XCTAssertEqual(list1.name, list2.name)
        XCTAssertEqual(list1.color, list2.color)
        XCTAssertEqual(list1.order, list2.order)
        XCTAssertEqual(list1.store, list2.store)

        equals(inv1: list1.inventory, inv2: list2.inventory)
        equals(arr1: list1.doneListItems.toArray(), arr2: list2.doneListItems.toArray())
        equals(arr1: list1.todoSections.toArray(), arr2: list2.todoSections.toArray())
        equals(arr1: list1.stashListItems.toArray(), arr2: list2.stashListItems.toArray())
    }

    static func equals(section1: Section, section2: Section) {
        XCTAssertEqual(section1.uuid, section2.uuid)
        XCTAssertEqual(section1.name, section2.name)
        XCTAssertEqual(section1.color, section2.color)
        XCTAssertEqual(section1.todoOrder, section2.todoOrder)
        XCTAssertEqual(section1.doneOrder, section2.doneOrder)
        XCTAssertEqual(section1.stashOrder, section2.stashOrder)
    }

    static func equals(category1: ProductCategory, category2: ProductCategory) {
        XCTAssertEqual(category1.uuid, category2.uuid)
        XCTAssertEqual(category1.name, category2.name)
        XCTAssertEqual(category1.color, category2.color)
    }

    static func equals(item1: Item, item2: Item) {
        XCTAssertEqual(item1.uuid, item2.uuid)
        XCTAssertEqual(item1.name, item2.name)
        XCTAssertEqual(item1.fav, item2.fav)
        XCTAssertEqual(item1.edible, item2.edible)

        equals(category1: item1.category, category2: item2.category)
    }

    static func equals(product1: Product, product2: Product) {
        XCTAssertEqual(product1.uuid, product2.uuid)
        XCTAssertEqual(product1.brand, product2.brand)
        XCTAssertEqual(product1.fav, product2.fav)

        equals(item1: product1.item, item2: product2.item)
    }

    static func equals(quantifiableProduct1: QuantifiableProduct, quantifiableProduct2: QuantifiableProduct) {
        XCTAssertEqual(quantifiableProduct1.uuid, quantifiableProduct2.uuid)
        XCTAssertEqual(quantifiableProduct1.baseQuantity, quantifiableProduct2.baseQuantity)
        XCTAssertEqual(quantifiableProduct1.secondBaseQuantity.value, quantifiableProduct2.secondBaseQuantity.value)
        XCTAssertEqual(quantifiableProduct1.fav, quantifiableProduct2.fav)

        equals(obj1: quantifiableProduct1.unit, obj2: quantifiableProduct2.unit)
        equals(product1: quantifiableProduct1.product, product2: quantifiableProduct2.product)
    }

    static func equals(storeProduct1: StoreProduct, storeProduct2: StoreProduct) {
        XCTAssertEqual(storeProduct1.uuid, storeProduct2.uuid)
        XCTAssertEqual(storeProduct1.refPrice.value, storeProduct2.refPrice.value)
        XCTAssertEqual(storeProduct1.refQuantity.value, storeProduct2.refQuantity.value)

        equals(quantifiableProduct1: storeProduct1.product, quantifiableProduct2: storeProduct2.product)
    }

    static func equals(listItem1: ListItem, listItem2: ListItem) {
        XCTAssertEqual(listItem1.uuid, listItem2.uuid)
        XCTAssertEqual(listItem1.quantity, listItem2.quantity)
        XCTAssertEqual(listItem1.note, listItem2.note)

        equals(section1: listItem1.section, section2: listItem2.section)
        equals(list1: listItem1.list, list2: listItem2.list)
        equals(storeProduct1: listItem1.product, storeProduct2: listItem2.product)

        // TODO remove when the fields in the original object are also removed
        XCTAssertEqual(listItem1.todoOrder, listItem2.todoOrder)
        XCTAssertEqual(listItem1.doneOrder, listItem2.doneOrder)
        XCTAssertEqual(listItem1.stashOrder, listItem2.stashOrder)
    }

    static func equals(obj1: HistoryItem, obj2: HistoryItem) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.addedDate, obj2.addedDate)
        XCTAssertEqual(obj1.quantity, obj2.quantity)
        XCTAssertEqual(obj1.paidPrice, obj2.paidPrice)

        equals(inv1: obj1.inventory, inv2: obj2.inventory)
        equals(quantifiableProduct1: obj1.product, quantifiableProduct2: obj2.product)
        equals(user1: obj1.user, user2: obj2.user)
    }
}


