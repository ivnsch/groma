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
 
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    
    func testNotFoundInventory() {
        let expectation = self.expectationWithDescription("Get not existing inventory")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            let inventory = Inventory(uuid: NSUUID().UUIDString, name: "foo")
            
            self.remoteInventoryItemsProvider.inventoryItems(inventory) {result in
                expect(result.success).to(beFalse())
                expect(result.successResult).to(beNil())
                expect(result.status) == RemoteStatusCode.NotFound
                
                expectation?.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    private func withAddedInventory(expectation: XCTestExpectation?, block: (addedInventory: Inventory) -> ()) {
        
        let inventoryInput = InventoryInput(uuid: NSUUID().UUIDString, name: "foo")
        
        self.remoteInventoryProvider.addInventory(inventoryInput) {result in
            expect(result.success).to(beTrue())
            expect(result.successResult).to(beNil())
            
            self.remoteInventoryProvider.inventories {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let inventories = result.successResult {
                    expect(inventories.count) == 1
                    
                    if let remoteInventory = inventories.first {
                        expect(remoteInventory.uuid).toNot(beEmpty())
                        expect(remoteInventory.name).toNot(beEmpty())
                        expect(remoteInventory.users).toNot(beEmpty())
                        // TODO test user in sharedusers is user1
                        
                        let inventory = Inventory(uuid: remoteInventory.uuid, name: remoteInventory.name)
                        
                        block(addedInventory: inventory)

                    } else {
                        expectation?.fulfill()
                    }
                } else {
                    expectation?.fulfill()
                }
            }
        }
        
    }
    
    func testAddInventory() {
        let expectation = self.expectationWithDescription("Get empty inventory")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            self!.withAddedInventory(expectation) {addedInventory in
                self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    if let inventoryItems = result.successResult {
                        expect(inventoryItems.count) == 0
                    }
                    
                    expectation!.fulfill()
                }
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testAddInventoryItems() {
        let expectation = self.expectationWithDescription("Add inventory items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            self!.withAddedInventory(expectation) {addedInventory in
                self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    if let inventoryItems = result.successResult {
                        expect(inventoryItems.count) == 0
                    }
                    
                    print("Add 2 items")
                    let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
                    let inventoryItem1 = InventoryItem(quantity: 2, product: product1, inventory: addedInventory)
                    let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
                    let inventoryItem2 = InventoryItem(quantity: 1, product: product2, inventory: addedInventory)
                    self!.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [inventoryItem1, inventoryItem2]) {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).to(beNil())
                        
                        print("Get items")
                        self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
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
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testIncrementInventoryItems() {
        let expectation = self.expectationWithDescription("Add inventory items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            self!.withAddedInventory(expectation) {addedInventory in
                self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    if let inventoryItems = result.successResult {
                        expect(inventoryItems.count) == 0
                    }
                    
                    print("Add 2 items")
                    let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
                    let inventoryItem1 = InventoryItem(quantity: 2, product: product1, inventory: addedInventory)
                    let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
                    let inventoryItem2 = InventoryItem(quantity: 1, product: product2, inventory: addedInventory)
                    self!.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [inventoryItem1, inventoryItem2]) {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).to(beNil())
                        
                        print("Increment the 2 added items")
                        let moreInventoryItem1 = InventoryItem(quantity: 10, product: product1, inventory: addedInventory)
                        let moreInventoryItem2 = InventoryItem(quantity: 30, product: product2, inventory: addedInventory)
                        self!.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [moreInventoryItem1, moreInventoryItem2]) {result in
                            expect(result.success).to(beTrue())
                            expect(result.successResult).to(beNil())
                            
                            print("Get items")
                            self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                                expect(result.success).to(beTrue())
                                expect(result.successResult).toNot(beNil())
                                
                                if let inventoryItems = result.successResult {
                                    expect(inventoryItems.count) == 2
                                    
                                    let expectedIncrementedItem1 = InventoryItem(quantity: inventoryItem1.quantity + moreInventoryItem1.quantity, product: inventoryItem1.product, inventory: addedInventory)
                                    let expectedIncrementedItem2 = InventoryItem(quantity: inventoryItem2.quantity + moreInventoryItem2.quantity, product: inventoryItem2.product, inventory: addedInventory)
                                    
                                    TestUtils.testRemoteInventoryItemMatches(inventoryItems[0], expectedIncrementedItem1)
                                    TestUtils.testRemoteInventoryItemMatches(inventoryItems[1], expectedIncrementedItem2)
                                }
                                
                                expectation?.fulfill()
                            }
                        }
                    }
                }
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    // more test cases
    // retrieve an existing inventory where user is not in shared users - should return not authorized or similar. Same with update and try to add or update items it.
    // create multiple inventories, check added/updates items update correct inventory
    // delete inventories and inventory items
    // add/remove shared users
    // users removes themselves from shared users, and when user is the last one (behaviour in this case is not defined yet)
    
}
