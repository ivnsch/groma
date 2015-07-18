//
//  TestInventory.swift
//  shoppin
//
//  Created by ischuetz on 17/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestInventory: XCTestCase {
 
    let remoteInventoryProvider = RemoteInventoryProvider()

    func testEmptyInventory() {
        var expectation = self.expectationWithDescription("Get empty inventory")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            self.remoteInventoryProvider.inventoryItems {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let inventoryItems = result.successResult {
                    expect(inventoryItems.count) == 0
                }

                expectation?.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testAddInventoryItems() {
        var expectation = self.expectationWithDescription("Add inventory items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            self.remoteInventoryProvider.inventoryItems {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let inventoryItems = result.successResult {
                    expect(inventoryItems.count) == 0
                }
                
                println("Add 2 items")
                let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
                let inventoryItem1 = InventoryItem(uuid: NSUUID().UUIDString, quantity: 2, product: product1)
                let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
                let inventoryItem2 = InventoryItem(uuid: NSUUID().UUIDString, quantity: 1, product: product2)
                self.remoteInventoryProvider.addToInventory([inventoryItem1, inventoryItem2]) {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).to(beNil())
                    
                    self.remoteInventoryProvider.inventoryItems {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).toNot(beNil())
                        
                        if let inventoryItems = result.successResult {
                            expect(inventoryItems.count) == 2
                            TestUtils.testRemoteInventoryItemMatches(inventoryItems[0], inventoryItem1)
                            TestUtils.testRemoteInventoryItemMatches(inventoryItems[1], inventoryItem2)
                        }
                        
                        expectation?.fulfill()
                    }
                }
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
