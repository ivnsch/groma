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

        CartTodoItemsTestUtils.skipPossibleIntro(app)

        CartTodoItemsTestUtils.selectFirstList(app)

        CartTodoItemsTestUtils.tapListItemsToggle(app)

        CartTodoItemsTestUtils.addQuickAddItemsToList(app, iterations: 3)

        // Swipe items to cart

        let todoTableView = app.tables.element(boundBy: 0)

        // Ensure table view is at top
        for _ in 0..<7 {
            todoTableView.swipeDown()
        }

        CartTodoItemsTestUtils.swipeAllTableViewItems(tableView: todoTableView)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }
}

