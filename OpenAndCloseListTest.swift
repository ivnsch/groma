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
        
        tablesQuery.staticTexts["Restore bundled products"].tap()
        app.alerts["Restore products"].collectionViews.buttons["Restore"].tap()
        app.alerts.collectionViews.buttons["Ok"].tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }

    
//    func foo() {
//        
//        let app = XCUIApplication()
//        app.buttons["Skip"].tap()
//        app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
//        app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Button).elementBoundByIndex(4).tap()
//        
//    }
    
//    
//    func test() {
//        
//        let app = XCUIApplication()
//        
//        let tabBarsQuery = app.tabBars
//        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
//        
//        
//        let element2 = app.otherElements.containingType(.NavigationBar, identifier:"UITabBar").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
//        let query: XCUIElementQuery = element2.childrenMatchingType(.Other)
//        
//        let element = query.elementBoundByIndex(1)
//        element.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
//        
//        let aKey = app.keys["A"]
//        aKey.tap()
//        app.textFields["Inventory name"]
//        
//        let submitButton = app.buttons["Submit"]
//        submitButton.tap()
//        
//        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(0).tap()
//        
//
//        let button = element.childrenMatchingType(.Button).elementBoundByIndex(4)
//        element.tap()
//        button.tap()
//        aKey.tap()
//        app.textFields["List name"]
//        submitButton.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(8).tap()
//        app.keys["B"].tap()
//        app.textFields["List name"]
//        
//        let submitButton2 = element2.childrenMatchingType(.Button).matchingIdentifier("Submit").elementBoundByIndex(0)
//        submitButton2.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(12).tap()
//        app.keys["C"].tap()
//        app.textFields["List name"]
//        submitButton2.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(16).tap()
//        app.keys["D"].tap()
//        app.textFields["List name"]
//        submitButton2.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(20).tap()
//        app.keys["E"].tap()
//        app.textFields["List name"]
//        submitButton2.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(24).tap()
//        app.keys["F"].tap()
//        app.textFields["List name"]
//        submitButton2.tap()
//        element.childrenMatchingType(.Button).elementBoundByIndex(28).tap()
//        app.keys["G"].tap()
//        app.textFields["List name"]
//        submitButton2.tap()
//        
//        for _ in 0..<2 {
//            let tablesQuery = app.tables
//            tablesQuery.staticTexts["A"].tap()
//            
//            let button = query.elementBoundByIndex(2).childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Button).elementBoundByIndex(0)
//            button.tap()
//            tablesQuery.staticTexts["B"].tap()
//            button.tap()
//            tablesQuery.staticTexts["C"].tap()
//            button.tap()
//            tablesQuery.staticTexts["D"].tap()
//            button.tap()
//            tablesQuery.staticTexts["E"].tap()
//            button.tap()
//            tablesQuery.staticTexts["F"].tap()
//            button.tap()
//            tablesQuery.staticTexts["G"].tap()
//            button.tap()
//        }
//    }
//    
    
    
    func test2() {

        
        
        let app = XCUIApplication()

        app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
        
        
        let element2 = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
        let element = element2.childrenMatchingType(.Other).elementBoundByIndex(1)
        
        
//        let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
//        element.tap()
        element.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
        app.keys["A"].tap()
        app.textFields["Inventory name"]
        app.buttons["Submit"].tap()
        
        
        
        
        let tabBarsQuery = app.tabBars
        tabBarsQuery.childrenMatchingType(.Button).elementBoundByIndex(0).tap()
//        
//        let element2 = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
//        let element = element2.childrenMatchingType(.Other).elementBoundByIndex(1)
        element.childrenMatchingType(.Button).elementBoundByIndex(4).tap()
        app.keys["A"].tap()
        app.textFields["List name"]
        app.buttons["Submit"].tap()
        
        element.childrenMatchingType(.Button).elementBoundByIndex(8).tap()
        app.keys["B"].tap()
        app.textFields["List name"]
        let submitButton = element2.childrenMatchingType(.Button).matchingIdentifier("Submit").elementBoundByIndex(0)
        submitButton.tap()
        
        element.childrenMatchingType(.Button).elementBoundByIndex(12).tap()
        app.keys["C"].tap()
        app.textFields["List name"]
        submitButton.tap()
        
        let tablesQuery = app.tables
        let aStaticText = tablesQuery.staticTexts["A"]
        aStaticText.tap()
        
        let element4 = element2.childrenMatchingType(.Other).elementBoundByIndex(2)
        let element3 = element4.childrenMatchingType(.Other).elementBoundByIndex(1)
        let button = element3.childrenMatchingType(.Button).elementBoundByIndex(2)
        button.tap()
        
        let collectionViewsQuery = app.scrollViews.otherElements.collectionViews
        collectionViewsQuery.staticTexts["Apples"].tap()
        collectionViewsQuery.staticTexts["Oranges"].tap()
        
        let button2 = element4.childrenMatchingType(.Button).element
        button2.tap()
//        button2.tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Apples").childrenMatchingType(.StaticText).matchingIdentifier("Apples").elementBoundByIndex(1).tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Oranges").childrenMatchingType(.StaticText).matchingIdentifier("Oranges").elementBoundByIndex(1).tap()
        
        let button3 = element4.childrenMatchingType(.Other).elementBoundByIndex(4).childrenMatchingType(.Button).element
        button3.tap()
        
        let tbBackButton = app.buttons["tb back"]
        tbBackButton.tap()
        
        let button4 = element3.childrenMatchingType(.Button).elementBoundByIndex(6)
        button4.tap()
        
        let bStaticText = tablesQuery.staticTexts["B"]
        bStaticText.tap()
        button.tap()
        collectionViewsQuery.staticTexts["Oranges"].tap()
        collectionViewsQuery.staticTexts["Blueberries"].tap()
        button2.tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Oranges").buttons["Undo"].tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Blueberries").childrenMatchingType(.StaticText).matchingIdentifier("Blueberries").elementBoundByIndex(1).tap()
        button3.tap()
        tbBackButton.tap()
        button4.tap()
        
        let cStaticText = tablesQuery.staticTexts["C"]
        cStaticText.tap()
        button.tap()
        collectionViewsQuery.staticTexts["Lemons"].tap()
        collectionViewsQuery.staticTexts["Nectarines"].tap()
        button2.tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Lemons").childrenMatchingType(.StaticText).matchingIdentifier("Lemons").elementBoundByIndex(1).tap()
        tablesQuery.cells.containingType(.StaticText, identifier:"Nectarines").childrenMatchingType(.StaticText).matchingIdentifier("Nectarines").elementBoundByIndex(1).tap()
        button3.tap()
        
        let table = element2.childrenMatchingType(.Table).element
        table.tap()
        table.tap()
        tbBackButton.tap()
        button4.tap()
        
        for _ in 0..<100 {
            aStaticText.tap()
            button3.tap()
            tbBackButton.tap()
            let button5 = element3.childrenMatchingType(.Button).elementBoundByIndex(0)
            button5.tap()
            bStaticText.tap()
            button3.tap()
            tbBackButton.tap()
            button5.tap()
            cStaticText.tap()
            button3.tap()
            tbBackButton.tap()
            button5.tap()
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
