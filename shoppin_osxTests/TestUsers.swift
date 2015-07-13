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
            let user = UserInput(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
            
            self.remoteProvider.register(user, handler: {result in
                
                expect(result.success).to(beTrue())
                expect(result.successResult).to(beNil())

                self.remoteProvider.register(user, handler: {result in
                    
                    expect(result.status) == RemoteStatusCode.AlreadyExists
                    expect(result.success).to(beFalse())
                    expect(result.successResult).to(beNil())
                    
                    expectation.fulfill()
                })
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testLoginAfterRegister() {
        var expectation = self.expectationWithDescription("register user")
        
        TestUtils.withClearedDatabase {
            
            println("register a user")
            let user = UserInput(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
            
            self.remoteProvider.register(user, handler: {result in
                
                expect(result.success).to(beTrue())
                expect(result.successResult).to(beNil())
                
                let loginData = LoginData(email: user.email, password: user.password)
                
                self.remoteProvider.login(loginData, handler: {result in
                    
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    expect(result.successResult?.token).toNot(beNil())
                    
                    expectation.fulfill()
                })
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
