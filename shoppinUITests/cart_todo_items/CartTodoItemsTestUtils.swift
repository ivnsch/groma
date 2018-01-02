//
//  CartTodoItemsTestUtils.swift
//  shoppinUITests
//
//  Created by Ivan Schuetz on 02.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import XCTest
@testable import Providers

class CartTodoItemsTestUtils {

    static func skipPossibleIntro(_ app: XCUIApplication) {
        if app.buttons["skip"].exists {
            app.buttons["skip"].tap()
        }
    }

    static func selectFirstList(_ app: XCUIApplication) {
        let listCell = app.tables.cells.element(boundBy: 0)
        listCell.tap()
    }

    static func tapListItemsToggle(_ app: XCUIApplication) {
        // Tap the quick add toggle
        // The are currently 2 toggles on the screen - the lists and list items toggle. Grab list items toggle
        let listItemsToggle = app.buttons.matching(identifier: "toggle").element(boundBy: 1)
        listItemsToggle.tap()
    }

    static func swipeUpALittle(element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -10))
        start.press(forDuration: 0, thenDragTo: finish)
    }
    
    static func addQuickAddItemsToList(_ app: XCUIApplication, iterations: Int) {
        let quickAddCollectionView = app.collectionViews.element(boundBy: 0)

        func tapItems() {
            var continueLoop = true
            for i in 0..<100 where continueLoop {
                let itemCell = quickAddCollectionView.cells.element(boundBy: i)
                if itemCell.exists {
                    if itemCell.isHittable {
                        itemCell.tap()
                    }
                } else {
                    continueLoop = false
                }
            }
        }

        for _ in 0..<iterations {
            tapItems()
            swipeUpALittle(element: quickAddCollectionView)
        }
    }

    static func swipeAllTableViewItems(tableView: XCUIElement) {
        var continueLoop = true
        while continueLoop {
            let listItemCell = tableView.cells.element(boundBy: 0)

            if listItemCell.exists {
                if listItemCell.isHittable {
                    listItemCell.swipeRight()
                }
            } else {
                continueLoop = false
            }
        }
    }

    // Assumes there's at least one item in the cart, otherwise the prices view is not visible
    static func openCart(_ app: XCUIApplication) {
        // Drag prices view up
        let pricesView = app.otherElements["pricesView"]
        let start = pricesView.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = pricesView.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -6))
        start.press(forDuration: 0, thenDragTo: finish)
    }
}
