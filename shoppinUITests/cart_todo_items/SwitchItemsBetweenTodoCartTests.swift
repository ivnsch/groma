import XCTest
@testable import Providers

class SwitchItemsBetweenTodoCartTests: XCTestCase {

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

    func testSendItemsToCartAndBack() {
        let app = XCUIApplication()

        CartTodoItemsTestUtils.skipPossibleIntro(app)

        CartTodoItemsTestUtils.selectFirstList(app)

        CartTodoItemsTestUtils.tapListItemsToggle(app)

        CartTodoItemsTestUtils.addQuickAddItemsToList(app, iterations: 1)

        // Swipe items to cart

        let todoTableView = app.tables.element(boundBy: 0)

        // Ensure table view is at top
        for _ in 0..<7 {
            todoTableView.swipeDown()
        }

        CartTodoItemsTestUtils.swipeAllTableViewItems(tableView: todoTableView)

        CartTodoItemsTestUtils.openCart(app)

        // Open cart and swipe all items back

        let cartTableView = app.tables.element(boundBy: 2)

        CartTodoItemsTestUtils.swipeAllTableViewItems(tableView: cartTableView)
    }


    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }
}

