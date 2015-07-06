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
        
        var expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            println("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            self.remoteProvider.add(firstList, handler: {result in
                
                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                if let remoteList = result.successResult {
                    println("test first list is returned correctly")
                    TestUtils.testRemoteListValid(remoteList)
                    TestUtils.testRemoteListMatches(remoteList, firstList)
                    
                    println("add second list")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                    self.remoteProvider.add(secondList, handler: {result in
                        
                        expect(result.success).to(beTrue())
                        TestUtils.testIfSuccessWithResult(result)
                        
                        if let remoteList = result.successResult {
                            println("test second list is returned correctly")
                            TestUtils.testRemoteListValid(remoteList)
                            TestUtils.testRemoteListMatches(remoteList, secondList)
                            
                            println("test lists are returned in GET, in correct order")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    
                                    expect(lists.count) == 2
                                    
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListMatches(lists[0], firstList)
                                    TestUtils.testRemoteListValid(lists[1])
                                    TestUtils.testRemoteListMatches(lists[1], secondList)
                                    
                                }
                                
                                expectation?.fulfill()
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
    
    func testRemoveList() {
        var expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            println("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            self.remoteProvider.add(firstList, handler: {result in

                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                println("add second list")
                let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                self.remoteProvider.add(secondList, handler: {result in

                    expect(result.success).to(beTrue())
                    TestUtils.testIfSuccessWithResult(result)
                    
                    if let remoteList = result.successResult {
                        println("test second list is returned correctly")
                        TestUtils.testRemoteListValid(remoteList)
                        TestUtils.testRemoteListMatches(remoteList, secondList)
                        
                        println("delete first list")
                        self.remoteProvider.remove(firstList, handler: {result in
                            
                            expect(result.success).to(beTrue())
                            
                            println("get lists - should only contain second added one")
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
        var expectation = self.expectationWithDescription("update lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            println("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
            self.remoteProvider.add(firstList, handler: {result in

                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                println("add second list")
                let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
                self.remoteProvider.add(secondList, handler: {result in 

                    expect(result.success).to(beTrue())
                    TestUtils.testIfSuccessWithResult(result)
                    
                    if let remoteList = result.successResult {
                        println("test second list is returned correctly")
                        TestUtils.testRemoteListValid(remoteList)
                        TestUtils.testRemoteListMatches(remoteList, secondList)
                        
                        println("update first list")
                        
                        let updatedList = List(uuid: firstList.uuid, name: "test-first-list-new-name", listItems: [])
                        self.remoteProvider.update(updatedList, handler: {result in 
                            expect(result.success).to(beTrue())
                            
                            println("result of POST list: \(result.success), uuid: \(firstList.uuid)")
                            
                            println("get lists - check update worked")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    expect(lists.count) == 2
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListMatches(lists[0], updatedList)
                                    TestUtils.testRemoteListValid(lists[1])
                                    TestUtils.testRemoteListMatches(lists[1], secondList)
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
