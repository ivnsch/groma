//
//  TestRequiresAuthentication.swift
//  shoppin
//
//  Created by ischuetz on 06/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestRequiresAuthentication: XCTestCase {
    
    let remoteProvider = RemoteListItemProvider()
    let remoteUserProvider = RemoteUserProvider()

    
    // TODO refactor - can we reduce each of these checks to 1-2 lines?
    func testNotAuthenticatedListItems() {
        var expectation = self.expectationWithDescription("not authenticated list items")
        
        let list = List(uuid: NSUUID().UUIDString, name: "some list")
        TestUtils.withClearedDatabase {[weak expectation] in
            self.remoteProvider.listItems(list: list) {result in
                TestUtils.testNotAuthenticated(result)
                expectation?.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testNotAuthenticatedLists() {
        var expectation = self.expectationWithDescription("not authenticated list items")
        TestUtils.withClearedDatabase {[weak expectation] in
            self.remoteProvider.lists {result in
                TestUtils.testNotAuthenticated(result)
                expectation?.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    // TODO do the rest

}
