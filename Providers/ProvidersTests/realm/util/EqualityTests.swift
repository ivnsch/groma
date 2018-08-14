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
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [List], arr2: [List]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [Section], arr2: [Section]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [ListItem], arr2: [ListItem], compareLists: Bool) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2, compareLists: compareLists)
        }
    }

    static func equals(arr1: [Item], arr2: [Item]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [ProductCategory], arr2: [ProductCategory]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [Product], arr2: [Product]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [QuantifiableProduct], arr2: [QuantifiableProduct]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [StoreProduct], arr2: [StoreProduct]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [DBSharedUser], arr2: [DBSharedUser]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [HistoryItem], arr2: [HistoryItem]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [InventoryItem], arr2: [InventoryItem]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [DBTextSpan], arr2: [DBTextSpan]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals(arr1: [Recipe], arr2: [Recipe]) {
        for(obj1, obj2) in zip(arr1, arr2) {
            equals(obj1: obj1, obj2: obj2)
        }
    }

    static func equals1(arr1: [Ingredient], arr2: [Ingredient]) {
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

    static func equals(obj1: DBSharedUser, obj2: DBSharedUser) {
        XCTAssertEqual(obj1.email, obj2.email)
    }

    static func equals(obj1: DBInventory, obj2: DBInventory) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.bgColor(), obj2.bgColor())
        XCTAssertEqual(obj1.order, obj2.order)

        equals(arr1: obj1.users.toArray(), arr2: obj2.users.toArray())
    }

    static func equals(obj1: InventoryItem, obj2: InventoryItem) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.quantity, obj2.quantity)

        equals(obj1: obj1.product, obj2: obj2.product)
        equals(obj1: obj1.inventory, obj2: obj2.inventory)
    }

    static func equals(obj1: List, obj2: List) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.color, obj2.color)
        XCTAssertEqual(obj1.order, obj2.order)
        XCTAssertEqual(obj1.store, obj2.store)

        equals(obj1: obj1.inventory, obj2: obj2.inventory)
        equals(arr1: obj1.doneListItems.toArray(), arr2: obj2.doneListItems.toArray(), compareLists: false)
        equals(arr1: obj1.todoSections.toArray(), arr2: obj2.todoSections.toArray())
        equals(arr1: obj1.stashListItems.toArray(), arr2: obj2.stashListItems.toArray(), compareLists: false)
    }

    static func equals(obj1: Section, obj2: Section) {
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.color, obj2.color)
        XCTAssertEqual(obj1.todoOrder, obj2.todoOrder)
        XCTAssertEqual(obj1.doneOrder, obj2.doneOrder)
        XCTAssertEqual(obj1.stashOrder, obj2.stashOrder)
    }

    static func equals(obj1: ProductCategory, obj2: ProductCategory) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.color, obj2.color)
    }

    static func equals(obj1: Item, obj2: Item) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.fav, obj2.fav)
        XCTAssertEqual(obj1.edible, obj2.edible)

        equals(obj1: obj1.category, obj2: obj2.category)
    }

    static func equals(obj1: Product, obj2: Product) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.brand, obj2.brand)
        XCTAssertEqual(obj1.fav, obj2.fav)

        equals(obj1: obj1.item, obj2: obj2.item)
    }

    static func equals(obj1: QuantifiableProduct, obj2: QuantifiableProduct) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.baseQuantity, obj2.baseQuantity)
        XCTAssertEqual(obj1.secondBaseQuantity, obj2.secondBaseQuantity)
        XCTAssertEqual(obj1.fav, obj2.fav)

        equals(obj1: obj1.unit, obj2: obj2.unit)
        equals(obj1: obj1.product, obj2: obj2.product)
    }

    static func equals(obj1: StoreProduct, obj2: StoreProduct) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.refPrice.value, obj2.refPrice.value)
        XCTAssertEqual(obj1.refQuantity.value, obj2.refQuantity.value)

        equals(obj1: obj1.product, obj2: obj2.product)
    }

    static func equals(obj1: ListItem, obj2: ListItem, compareLists: Bool) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.quantity, obj2.quantity)
        XCTAssertEqual(obj1.note, obj2.note)

        equals(obj1: obj1.section, obj2: obj2.section)
        if compareLists {
            equals(obj1: obj1.list, obj2: obj2.list)
        }
        equals(obj1: obj1.product, obj2: obj2.product)

        // TODO remove when the fields in the original object are also removed
        XCTAssertEqual(obj1.todoOrder, obj2.todoOrder)
        XCTAssertEqual(obj1.doneOrder, obj2.doneOrder)
        XCTAssertEqual(obj1.stashOrder, obj2.stashOrder)
    }

    static func equals(obj1: HistoryItem, obj2: HistoryItem) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.addedDate, obj2.addedDate)
        XCTAssertEqual(obj1.quantity, obj2.quantity)
        XCTAssertEqual(obj1.paidPrice, obj2.paidPrice)

        equals(obj1: obj1.inventory, obj2: obj2.inventory)
        equals(obj1: obj1.product, obj2: obj2.product)
        equals(obj1: obj1.user, obj2: obj2.user)
    }
    
    static func equals(obj1: DBTextSpan, obj2: DBTextSpan) {
        XCTAssertEqual(obj1.start, obj2.start)
        XCTAssertEqual(obj1.length, obj2.length)
        XCTAssertEqual(obj1.attribute, obj2.attribute)
    }

    static func equals(obj1: Recipe, obj2: Recipe) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.name, obj2.name)
        XCTAssertEqual(obj1.color, obj2.color)
        XCTAssertEqual(obj1.fav, obj2.fav)
        XCTAssertEqual(obj1.text, obj2.text)

        equals(arr1: obj1.textAttributeSpans.toArray(), arr2: obj2.textAttributeSpans.toArray())
    }

    static func equals(obj1: Ingredient, obj2: Ingredient) {
        XCTAssertEqual(obj1.uuid, obj2.uuid)
        XCTAssertEqual(obj1.quantity, obj2.quantity)
        XCTAssertEqual(obj1.fraction, obj2.fraction)
        XCTAssertEqual(obj1.fractionNumerator, obj2.fractionNumerator)
        XCTAssertEqual(obj1.fractionDenominator, obj2.fractionDenominator)

        equals(obj1: obj1.unit, obj2: obj2.unit)
        equals(obj1: obj1.item, obj2: obj2.item)
        equals(obj1: obj1.recipe, obj2: obj2.recipe)

        XCTAssertEqual(obj1.pName, obj2.pName)
        XCTAssertEqual(obj1.pBrand, obj2.pBrand)
        XCTAssertEqual(obj1.pBase, obj2.pBase)
        XCTAssertEqual(obj1.pSecondBase, obj2.pSecondBase)
        XCTAssertEqual(obj1.pQuantity, obj2.pQuantity)
        XCTAssertEqual(obj1.pUnit, obj2.pUnit)
    }

}


extension Array where Element == Section {
    func sortedByName() -> Array<Section> {
        return sorted(by: { (item1, item2) -> Bool in
            item1.name > item2.name
        })
    }
}
