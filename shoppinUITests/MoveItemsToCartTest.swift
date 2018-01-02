//
//  MoveItemsToCartTest.swift
//  shoppinUITests
//
//  Created by Ivan Schuetz on 31.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import XCTest
@testable import Providers

class MoveItemsToCartTest: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        //        let app = XCUIApplication()

        // not sure this is working
        let realmProvider = RealmGlobalProvider()
        realmProvider.clearAppForUITests()
    }

    func testMoveManyItemsToCart() {
        let app = XCUIApplication()

        if app.buttons["skip"].exists {
            app.buttons["skip"].tap()
        }

        // Select first list
        let listCell = app.tables.cells.element(boundBy: 0)
        listCell.tap()

        // Tap the quick add toggle
        // The are currently 2 toggles on the screen - the lists and list items toggle. Grab list items toggle
        let listItemsToggle = app.buttons.matching(identifier: "toggle").element(boundBy: 1)
        listItemsToggle.tap()

        let quickAddCollectionView = app.collectionViews.element(boundBy: 0)

        // Add many items to list
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
//                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        func swipeUpALittle(_ element: XCUIElement) {
            let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            let finish = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -10))
            start.press(forDuration: 0, thenDragTo: finish)
        }

        tapItems()
        swipeUpALittle(quickAddCollectionView)
        tapItems()
        swipeUpALittle(quickAddCollectionView)
        tapItems()

        // Swipe items to cart
        let todoTableView = app.tables.element(boundBy: 0)

        todoTableView.swipeDown()
        todoTableView.swipeDown()
        todoTableView.swipeDown()
        todoTableView.swipeDown()
        todoTableView.swipeDown()
        todoTableView.swipeDown()
        todoTableView.swipeDown()

        func swipeItems() {
            var continueLoop = true
            for _ in 0..<1000 where continueLoop {
                // Send a list item to cart (otherwise prices view doesn't show)
                let listItemCell = todoTableView.cells.element(boundBy: 0)

                if listItemCell.exists {
                    if listItemCell.isHittable {
                        listItemCell.swipeRight()
                    }
                } else {
                    continueLoop = false
                }
//                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        swipeItems()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }
}

