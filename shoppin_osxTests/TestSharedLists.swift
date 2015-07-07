//
//  TestSharedLists.swift
//  shoppin
//
//  Created by ischuetz on 07/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestSharedLists: XCTestCase {

//    let remoteProvider = RemoteListItemProvider()
//
//    func testExample() {
//        
//        var expectation = self.expectationWithDescription("2 users add lists separatedly")
//        
//        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
//            
//            println("add first list")
//            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [])
//            self.remoteProvider.add(firstList, handler: {result in
//                
//                expect(result.success).to(beTrue())
//                TestUtils.testIfSuccessWithResult(result)
//                
//                if let remoteList = result.successResult {
//                    println("test first list is returned correctly")
//                    TestUtils.testRemoteListValid(remoteList)
//                    TestUtils.testRemoteListMatches(remoteList, firstList)
//                    
//                    println("add second list")
//                    let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [])
//                    self.remoteProvider.add(secondList, handler: {result in
//                        
//                        expect(result.success).to(beTrue())
//                        TestUtils.testIfSuccessWithResult(result)
//                        
//                        if let remoteList = result.successResult {
//                            println("test second list is returned correctly (post response)")
//                            TestUtils.testRemoteListValid(remoteList)
//                            TestUtils.testRemoteListMatches(remoteList, secondList)
//                            
//                            
//                            
//                            // let a second user add a list
//                            TestUtils.withNewLoggedInAccountUser1 {[weak expectation] loginData in
//                                expect(result.success).to(beTrue())
//                                TestUtils.testIfSuccessWithResult(result)
//                                
//                                self.remoteProvider.add(firstList, handler: {result in
//                                    
//                                    expect(result.success).to(beTrue())
//                                    TestUtils.testIfSuccessWithResult(result)
//                                    
//                                    if let remoteList = result.successResult {
//                                        println("test list added by second user is returned correctly (post response)")
//                                        TestUtils.testRemoteListValid(remoteList)
//                                        TestUtils.testRemoteListMatches(remoteList, firstList)
//                                        
//
//                                        // TODO the login token from first user is overwritten now - test have to be modified to support this kind of multi-user test
//                                        // one possibility could be to store the tokens in memory, but has to be careful not introducing new issues
////                                        println("test lists added by first user are returned correctly")
////                                        self.remoteProvider.lists {result in
////                                            expect(result.success).toNot(beNil())
////                                            if let lists = result.successResult {
////                                                expect(lists.count) == 2
////                                                TestUtils.testRemoteListValid(lists[0])
////                                                TestUtils.testRemoteListMatches(lists[0], firstList)
////                                                TestUtils.testRemoteListValid(lists[1])
////                                                TestUtils.testRemoteListMatches(lists[1], secondList)
////                                            }
////                                            expectation?.fulfill()
////                                        }
//                                        
//                                    } else {
//                                        expectation?.fulfill()
//                                    }
//                                })
//                            }
//                            
////                            println("test lists are returned in GET, in correct order")
////                            self.remoteProvider.lists {result in
////                                expect(result.success).toNot(beNil())
////                                
////                                if let lists = result.successResult {
////                                    
////                                    expect(lists.count) == 2
////                                    
////                                    TestUtils.testRemoteListValid(lists[0])
////                                    TestUtils.testRemoteListMatches(lists[0], firstList)
////                                    TestUtils.testRemoteListValid(lists[1])
////                                    TestUtils.testRemoteListMatches(lists[1], secondList)
////                                    
////                                }
////                                
////                                expectation?.fulfill()
////                            }
//                            
//                        } else {
//                            expectation?.fulfill()
//                        }
//                    })
//                    
//                } else {
//                    expectation?.fulfill()
//                }
//            })
//        }
//        self.waitForExpectationsWithTimeout(5.0, handler: nil)
//    }
}