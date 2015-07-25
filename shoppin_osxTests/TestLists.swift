//
//  TestLists.swift
//  shoppin
//
//  Created by ischuetz on 20/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestLists: XCTestCase {

    let remoteProvider = RemoteListItemProvider()

    func testAddList() {
        
        let expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            let firstListWithSharedUsers = ListWithSharedUsersInput(list: firstList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstListWithSharedUsers, handler: {result in
                
                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                if let remoteList = result.successResult {
                    print("test first list is returned correctly")
                    TestUtils.testRemoteListValid(remoteList)
                    TestUtils.testRemoteListMatches(remoteList, firstList)
                    
                    print("add second list")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                    let secondListWithSharedUsers = ListWithSharedUsersInput(list: secondList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
                    self.remoteProvider.add(secondListWithSharedUsers, handler: {result in
                        
                        expect(result.success).to(beTrue())
                        TestUtils.testIfSuccessWithResult(result)
                        
                        if let remoteList = result.successResult {
                            print("test second list is returned correctly")
                            TestUtils.testRemoteListValid(remoteList)
                            TestUtils.testRemoteListMatches(remoteList, secondList)
                            
                            print("test lists are returned in GET, in correct order")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    
                                    expect(lists.count) == 2
                                    
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[0], firstListWithSharedUsers)
                                    TestUtils.testRemoteListValid(lists[1])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[1], secondListWithSharedUsers)
                                    
                                    
                                    print("should get error response when adding a list with a shared user that is not registered")
                                    let thirdList = List(uuid: NSUUID().UUIDString, name: "test-third-list", listItems: [])
                                    let thirdListWithSharedUsers = ListWithSharedUsersInput(list: thirdList, users: [SharedUserInput(email: "does@not.exist")])
                                    self.remoteProvider.add(thirdListWithSharedUsers, handler: {result in
                                        expect(result.success).to(beFalse())
                                        expect(result.successResult).to(beNil())
                                        expect(result.status) == RemoteStatusCode.NotFound // TODO this error has to be improved (*user* not found, and return list of not found users). For now this is all that can be tested
                                        
                                        expectation?.fulfill()
                                    })
                                    
                                } else {
                                    expectation?.fulfill()
                                }
                                
                            }
                            
                        } else {
                            expectation?.fulfill()
                        }
                    })
                    
                } else {
                    expectation?.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    // TODO adding a list when there's already one should return already exists! right now this returns success with the added list, also add test for this
    
    func testRemoveList() {
        let expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            let firstListWithSharedUsers = ListWithSharedUsersInput(list: firstList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstListWithSharedUsers, handler: {result in

                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                print("add second list")
                let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                let secondListWithSharedUsers = ListWithSharedUsersInput(list: secondList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
                self.remoteProvider.add(secondListWithSharedUsers, handler: {result in

                    expect(result.success).to(beTrue())
                    TestUtils.testIfSuccessWithResult(result)
                    
                    if let remoteList = result.successResult {
                        print("test second list is returned correctly")
                        TestUtils.testRemoteListValid(remoteList)
                        TestUtils.testRemoteListMatches(remoteList, secondList)
                        
                        print("delete first list")
                        self.remoteProvider.remove(firstList, handler: {result in
                            
                            expect(result.success).to(beTrue())
                            
                            print("get lists - should only contain second added one")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    
                                    expect(lists.count) == 1
                                    
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListMatches(lists[0], secondList)
                                }
                                
                                expectation?.fulfill()
                            }
                        })
                    } else {
                        expectation?.fulfill()
                    }
                })
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testUpdateList() {
        let expectation = self.expectationWithDescription("update lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            let firstListWithSharedUsers = ListWithSharedUsersInput(list: firstList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstListWithSharedUsers, handler: {result in

                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                if let list = result.successResult {
                    TestUtils.testRemoteListMatches(list, firstList)
                    
                    expect(list.users.count) == 1
                    let user = list.users.first!
                    expect(user.uuid).toNot(beEmpty())
                    expect(user.email) == loginData.email
                    expect(user.firstName) == TestUtils.userInput1.firstName
                    expect(user.lastName) == TestUtils.userInput1.lastName
                }
                
                print("add second list")
                let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                let secondListWithSharedUsers = ListWithSharedUsersInput(list: secondList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
                self.remoteProvider.add(secondListWithSharedUsers, handler: {result in

                    expect(result.success).to(beTrue())
                    TestUtils.testIfSuccessWithResult(result)
                    
                    print("test second list is returned correctly")
                    if let list = result.successResult {
                        TestUtils.testRemoteListWithSharedUsersMatches(list, secondListWithSharedUsers)
                        
                        expect(list.users.count) == 1
                        let user = list.users.first!
                        expect(user.uuid).toNot(beEmpty())
                        expect(user.email) == loginData.email
                        expect(user.firstName) == TestUtils.userInput1.firstName
                        expect(user.lastName) == TestUtils.userInput1.lastName
                    }
                    
                    if let remoteList = result.successResult {
                     
                        print("update first list")
                        let updatedList = List(uuid: firstList.uuid, name: "test-first-list-new-name", listItems: [])
                        // TODO test validtion when we send empty shared users. The server should reject this (it's not implemented yet)
                        let updatedListWithSharedUsers = ListWithSharedUsersInput(list: updatedList, users: [SharedUserInput(email: TestUtils.userInput1.email)])
                        self.remoteProvider.update(updatedListWithSharedUsers, handler: {result in
                            expect(result.success).to(beTrue())
                            expectation?.fulfill()

                            print("result of POST list: \(result.success), uuid: \(firstList.uuid)")
                            
                            print("get lists - check update worked")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    expect(lists.count) == 2
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[0], updatedListWithSharedUsers)
                                    TestUtils.testRemoteListValid(lists[1])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[1], secondListWithSharedUsers)
                                }
                                
                                expectation?.fulfill()
                            }
                        })
                        
                    } else {
                        expectation?.fulfill()
                    }
                })
            })
        }
        self.waitForExpectationsWithTimeout(15.0, handler: nil)
    }
}
