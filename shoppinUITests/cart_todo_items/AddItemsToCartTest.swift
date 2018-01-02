//
//  AddItemsToCartTest.swift
//  shoppinUITests
//
//  Created by Ivan Schuetz on 31.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import XCTest
@testable import Providers

class AddItemsToCartTest: XCTestCase {

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

    func testAddManyItemsToCart() {
        let app = XCUIApplication()

        CartTodoItemsTestUtils.skipPossibleIntro(app)

        CartTodoItemsTestUtils.selectFirstList(app)

        // Send a list item to cart (otherwise prices view doesn't show)
        let listItemCell = app.tables.cells.element(boundBy: 0)
        listItemCell.swipeRight()

        CartTodoItemsTestUtils.openCart(app)

        CartTodoItemsTestUtils.tapListItemsToggle(app)

        CartTodoItemsTestUtils.addQuickAddItemsToList(app, iterations: 7)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }
}
