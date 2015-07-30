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
        
        let inventoryInput = Inventory(uuid: NSUUID().UUIDString, name: "foo")
        
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
                
                self!.remoteInventoryProvider.inventories {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    if let inventories = result.successResult {
                        expect(inventories.count) == 1
                        
                        if let remoteInventory = inventories.first {

                            TestUtils.testRemoteInventoryMatches(remoteInventory, addedInventory)
                            expect(remoteInventory.users.count) == 1 // user is added automatically by server, using the token
                            
                            self!.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                                expect(result.success).to(beTrue())
                                expect(result.successResult).toNot(beNil())
                                
                                if let inventoryItems = result.successResult {
                                    expect(inventoryItems.count) == 0
                                }
                                
                                expectation!.fulfill()
                            }
                            
                        } else {
                            expectation!.fulfill()
                        }
                        
                    } else {
                        expectation!.fulfill()
                    }
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
    
    
    func testInventoriesSync() {
        let expectation = self.expectationWithDescription("Sync inventories")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            // Simulate a local database: 4 inventories
            let inventory1 = Inventory(uuid: NSUUID().UUIDString, name: "foo")
            let inventory2 = Inventory(uuid: NSUUID().UUIDString, name: "bar")
            let inventory3 = Inventory(uuid: NSUUID().UUIDString, name: "pan")
            let inventory4 = Inventory(uuid: NSUUID().UUIDString, name: "lol")
            
            // Part 1. add 3 first items and try to remove the last one. We expect adding to succeed and the removal to be ignored
            self!.remoteInventoryProvider.syncInventories ([inventory1, inventory2, inventory3], toRemove: [inventory4]) {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let successResult = result.successResult {
                    expect(successResult.items.count) == 3
                    expect(successResult.couldNotUpdate.count) == 0
                    expect(successResult.couldNotDelete.count) == 0 // item is couldNotDelete only when it was not possible to delete due to a conflict in the server (there's another version of the item). Trying to delete an item that doesn't exist in the server is ignored
                    
                    TestUtils.testRemoteInventoryMatches(successResult.items[0], inventory1)
                    TestUtils.testRemoteInventoryMatches(successResult.items[1], inventory2)
                    TestUtils.testRemoteInventoryMatches(successResult.items[2], inventory3)
                    
                    // Part 2. Update inventory1, delete inventory 3 and add inventory4
                    // Note that for now we send always the complete database - TODO implement or test that we send only added/modified
                    let updatedInventory1 = Inventory(uuid: inventory1.uuid, name: "foo-updated", lastServerUpdate: successResult.items[0].lastUpdate)
                    let updatedInventory2 = Inventory(uuid: inventory2.uuid, name: inventory2.name, lastServerUpdate: successResult.items[1].lastUpdate)
                    let updatedInventory3 = Inventory(uuid: inventory3.uuid, name: inventory3.name, lastServerUpdate: successResult.items[2].lastUpdate)

                    self!.remoteInventoryProvider.syncInventories ([updatedInventory1, updatedInventory2, inventory4], toRemove: [updatedInventory3]) {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).toNot(beNil())
                        
                        if let successResult = result.successResult {
                            expect(successResult.items.count) == 3
                            expect(successResult.couldNotUpdate.count) == 0
                            expect(successResult.couldNotDelete.count) == 0 // item is couldNotDelete only when it was not possible to delete due to a conflict in the server (so another version of the item is still in the server). Trying to delete an item that doesn't exist in the server is considered a succesful delete.
                            
                            TestUtils.testRemoteInventoryMatches(successResult.items[0], updatedInventory1)
                            TestUtils.testRemoteInventoryMatches(successResult.items[1], updatedInventory2)
                            TestUtils.testRemoteInventoryMatches(successResult.items[2], inventory4)
                            
                            // Part 3. Try an update with an out of sync item (last server update date is older than in the server) and a synched item (last server update date is the same as in server)
                            // and a delete with an item out of sync
                            // we expect first one to return a failed sync item, the second one to succeed and the removal to also return a failed sync item
                            let outOfSyncInventory1 = Inventory(uuid: inventory1.uuid, name: "will-not-be-used", lastServerUpdate: NSDate(timeIntervalSinceNow: -3600))
                            let updatedAgainInventory2 = Inventory(uuid: inventory2.uuid, name: "my-second update", lastServerUpdate: successResult.items[1].lastUpdate)
                            let outOfSyncInventory4 = Inventory(uuid: inventory4.uuid, name: "doesn't matter", lastServerUpdate: NSDate(timeIntervalSinceNow: -10))
                            
                            self!.remoteInventoryProvider.syncInventories ([outOfSyncInventory1, updatedAgainInventory2], toRemove: [outOfSyncInventory4]) {result in
                                expect(result.success).to(beTrue())
                                expect(result.successResult).toNot(beNil())
                                
                                if let successResult = result.successResult {
                                    expect(successResult.items.count) == 3
                                    expect(successResult.couldNotUpdate.count) == 1
                                    expect(successResult.couldNotDelete.count) == 1
                                    
                                    TestUtils.testRemoteInventoryMatches(successResult.items[0], updatedInventory1)
                                    TestUtils.testRemoteInventoryMatches(successResult.items[1], updatedAgainInventory2)
                                    TestUtils.testRemoteInventoryMatches(successResult.items[2], inventory4)
                                    
                                    expect(successResult.couldNotUpdate[0] == outOfSyncInventory1.uuid)
                                    expect(successResult.couldNotDelete[0] == outOfSyncInventory4.uuid)
                                }

                                expectation?.fulfill()
                            }
                            
                        } else {
                            expectation?.fulfill()
                        }
                    }

                } else {
                    expectation?.fulfill()
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
