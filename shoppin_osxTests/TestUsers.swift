//
//  TestUsers.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestUsers: XCTestCase {

    let remoteProvider = RemoteUserProvider()

    func testRegister() {
        var expectation = self.expectationWithDescription("register user")
        
        TestUtils.withClearedDatabase {
            
            println("register a user")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            
            let user = User(email: "foo@bar.com", password: "password123", firstName: "azucar", lastName: "schuetz")
            
            self.remoteProvider.register(user, handler: {try in
                
                expect(try.success).toNot(beNil())
                expect(try.success ?? false).to(beTrue())

                self.remoteProvider.register(user, handler: {try in
                    
                    expect(try.success).to(beNil())
                    expect(try.error).toNot(beNil())
                    
                    let status = RemoteStatusCode(rawValue: try.error!.code)
                    expect(status).toNot(beNil())
                    expect(status) == RemoteStatusCode.AlreadyExists
                    
                    expectation.fulfill()
                })
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
