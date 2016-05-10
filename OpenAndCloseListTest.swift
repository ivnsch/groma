//
//  OpenAndCloseListTest.swift
//  shoppin
//
//  Created by ischuetz on 09/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import XCTest

// Trying to reproduce a bug with the path animation in list items top bar, which freezes the app.
class OpenAndCloseListTest: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        let app = XCUIApplication()
        app.buttons["Skip"].tap()
        
        let tabBarsQuery = app.tabBars
        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Settings"].tap()
        tablesQuery.staticTexts["Clear all data"].tap()
        
        let okButton = app.alerts.collectionViews.buttons["Ok"]
        okButton.tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }

    func test() {
        
        let app = XCUIApplication()
        
        let tabBarsQuery = app.tabBars
        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
        
        let query: XCUIElementQuery = app.otherElements.containingType(.NavigationBar, identifier:"UITabBar").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other)
        
        let element = query.elementBoundByIndex(1)
        element.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
        
        let aKey = app.keys["A"]
        aKey.tap()
        app.textFields["Inventory name"]
        
        let submitButton = app.buttons["Submit"]
        submitButton.tap()
        
        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(0).tap()
        
        element.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
        aKey.tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(8).tap()
        
        let app2 = app
        app2.keys["B"].tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(12).tap()
        app2.keys["C"].tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(16).tap()
        app2.keys["D"].tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(20).tap()
        app2.keys["E"].tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(24).tap()
        app2.keys["F"].tap()
        app.textFields["List name"]
        submitButton.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(28).tap()
        app2.keys["G"].tap()
        app.textFields["List name"]
        submitButton.tap()
        
        
        for _ in 0..<1000 {
            let tablesQuery = app.tables
            tablesQuery.staticTexts["A"].tap()
            
            let button = query.elementBoundByIndex(2).childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Button).elementBoundByIndex(0)
            button.tap()
            tablesQuery.staticTexts["B"].tap()
            button.tap()
            tablesQuery.staticTexts["C"].tap()
            button.tap()
            tablesQuery.staticTexts["D"].tap()
            button.tap()
            tablesQuery.staticTexts["E"].tap()
            button.tap()
            tablesQuery.staticTexts["F"].tap()
            button.tap()
            tablesQuery.staticTexts["G"].tap()
            button.tap()
        }
    }
    
//    func testExample() {
//        let app = XCUIApplication()
//        
//        XCUIApplication().buttons["Skip"].tap()
//        
//        let aStaticText = app.tables.staticTexts["A"]
//        aStaticText.tap()
//        
//        let button = app.otherElements.containingType(.NavigationBar, identifier:"UITabBar").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(2).childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Button).elementBoundByIndex(0)
//        button.tap()
//
//        for _ in 0..<100 {
//            aStaticText.tap() // open list
//            button.tap() // close list
//        }
//    }
    
}
