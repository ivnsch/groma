//
//  TestInventory.swift
//  shoppin
//
//  Created by ischuetz on 17/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

//import XCTest
//import Nimble
//
//class TestInventory: XCTestCase {
// 
//    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
//
//    func testEmptyInventory() {
//        var expectation = self.expectationWithDescription("Get empty inventory")
//        
//        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
//            
//            self.remoteInventoryItemsProvider.inventoryItems {result in
//                expect(result.success).to(beTrue())
//                expect(result.successResult).toNot(beNil())
//                
//                if let inventoryItems = result.successResult {
//                    expect(inventoryItems.count) == 0
//                }
//
//                expectation?.fulfill()
//            }
//        }
//        self.waitForExpectationsWithTimeout(5.0, handler: nil)
//    }
//    
//    func testAddInventoryItems() {
//        var expectation = self.expectationWithDescription("Add inventory items")
//        
//        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
//            
//            self.remoteInventoryItemsProvider.inventoryItems {result in
//                expect(result.success).to(beTrue())
//                expect(result.successResult).toNot(beNil())
//                
//                if let inventoryItems = result.successResult {
//                    expect(inventoryItems.count) == 0
//                }
//                
//                print("Add 2 items")
//                let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
//                let inventoryItem1 = InventoryItem(quantity: 2, product: product1)
//                let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
//                let inventoryItem2 = InventoryItem(quantity: 1, product: product2)
//                self.remoteInventoryProvider.addToInventory([inventoryItem1, inventoryItem2]) {result in
//                    expect(result.success).to(beTrue())
//                    expect(result.successResult).to(beNil())
//                    
//                    print("Get items")
//                    self.remoteInventoryProvider.inventoryItems {result in
//                        expect(result.success).to(beTrue())
//                        expect(result.successResult).toNot(beNil())
//                        
//                        if let inventoryItems = result.successResult {
//                            expect(inventoryItems.count) == 2
//                            TestUtils.testRemoteInventoryItemMatches(inventoryItems[0], inventoryItem1)
//                            TestUtils.testRemoteInventoryItemMatches(inventoryItems[1], inventoryItem2)
//                        }
//                        
//                        expectation?.fulfill()
//                    }
//                }
//            }
//        }
//        self.waitForExpectationsWithTimeout(5.0, handler: nil)
//    }
//    
//    func testIncrementInventoryItems() {
//        var expectation = self.expectationWithDescription("Add inventory items")
//        
//        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
//            
//            self.remoteInventoryItemsProvider.inventoryItems {result in
//                expect(result.success).to(beTrue())
//                expect(result.successResult).toNot(beNil())
//                
//                if let inventoryItems = result.successResult {
//                    expect(inventoryItems.count) == 0
//                }
//                
//                print("Add 2 items")
//                let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
//                let inventoryItem1 = InventoryItem(quantity: 2, product: product1)
//                let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
//                let inventoryItem2 = InventoryItem(quantity: 1, product: product2)
//                self.remoteInventoryProvider.addToInventory([inventoryItem1, inventoryItem2]) {result in
//                    expect(result.success).to(beTrue())
//                    expect(result.successResult).to(beNil())
//                    
//                    print("Increment the 2 added items")
//                    let moreInventoryItem1 = InventoryItem(quantity: 10, product: product1)
//                    let moreInventoryItem2 = InventoryItem(quantity: 30, product: product2)
//                    self.remoteInventoryProvider.addToInventory([moreInventoryItem1, moreInventoryItem2]) {result in
//                        expect(result.success).to(beTrue())
//                        expect(result.successResult).to(beNil())
//                        
//                        print("Get items")
//                        self.remoteInventoryProvider.inventoryItems {result in
//                            expect(result.success).to(beTrue())
//                            expect(result.successResult).toNot(beNil())
//                            
//                            if let inventoryItems = result.successResult {
//                                expect(inventoryItems.count) == 2
//                                
//                                let expectedIncrementedItem1 = InventoryItem(quantity: inventoryItem1.quantity + moreInventoryItem1.quantity, product: inventoryItem1.product)
//                                let expectedIncrementedItem2 = InventoryItem(quantity: inventoryItem2.quantity + moreInventoryItem2.quantity, product: inventoryItem2.product)
//                                
//                                TestUtils.testRemoteInventoryItemMatches(inventoryItems[0], expectedIncrementedItem1)
//                                TestUtils.testRemoteInventoryItemMatches(inventoryItems[1], expectedIncrementedItem2)
//                            }
//                            
//                            expectation?.fulfill()
//                        }
//                    }
//                }
//            }
//        }
//        self.waitForExpectationsWithTimeout(5.0, handler: nil)
//    }
//}
