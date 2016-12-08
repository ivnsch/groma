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
 
    static let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    static let remoteInventoryProvider = RemoteInventoryProvider()
    
    static let inventory1 = DBInventory(uuid: NSUUID().UUIDString, name: "foo")
    
    static func withAddedInventory(expectation: XCTestExpectation?, block: (addedInventory: DBInventory) -> ()) {
        
        self.remoteInventoryProvider.addInventory(self.inventory1) {result in
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
                        
                        let inventory = DBInventory(uuid: remoteInventory.uuid, name: remoteInventory.name)
                        
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
    
    func testNotFoundInventory() {
        let expectation = self.expectationWithDescription("Get not existing inventory")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            let inventory = DBInventory(uuid: NSUUID().UUIDString, name: "foo")
            
            TestInventory.remoteInventoryItemsProvider.inventoryItems(inventory) {result in
                expect(result.success).to(beFalse())
                expect(result.successResult).to(beNil())
                expect(result.status) == RemoteStatusCode.NotFound
                
                expectation?.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    

    
    func testAddInventory() {
        let expectation = self.expectationWithDescription("Get empty inventory")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            TestInventory.withAddedInventory(expectation) {addedInventory in
                
                TestInventory.remoteInventoryProvider.inventories {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    
                    if let inventories = result.successResult {
                        expect(inventories.count) == 1
                        
                        if let remoteInventory = inventories.first {

                            TestUtils.testRemoteInventoryMatches(remoteInventory, addedInventory)
                            expect(remoteInventory.users.count) == 1 // user is added automatically by server, using the token
                            
                            TestInventory.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
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
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            TestInventory.withAddedInventory(expectation) {addedInventory in
                TestInventory.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
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
                    let inventoryItemWithHistory1 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem1, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                    let inventoryItemWithHistory2 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem2, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                    TestInventory.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [inventoryItemWithHistory1, inventoryItemWithHistory2]) {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).to(beNil())
                        
                        print("Get items")
                        TestInventory.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
                            expect(result.success).to(beTrue())
                            expect(result.successResult).toNot(beNil())
                            
                            if let inventoryItems = result.successResult {
                                expect(inventoryItems.count) == 2
                                TestUtils.testRemoteInventoryItemMatches(inventoryItems[0], inventoryItem1)
                                TestUtils.testRemoteInventoryItemMatches(inventoryItems[1], inventoryItem2)
                                
                                expectation?.fulfill()
                            }
                        }
                    }
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testIncrementInventoryItems() {
        let expectation = self.expectationWithDescription("Add inventory items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            TestInventory.withAddedInventory(expectation) {addedInventory in
                TestInventory.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
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
                    let inventoryItemWithHistory1 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem1, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                    let inventoryItemWithHistory2 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem2, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                    
                    TestInventory.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [inventoryItemWithHistory1, inventoryItemWithHistory2]) {result in
                        expect(result.success).to(beTrue())
                        expect(result.successResult).to(beNil())
                        
                        print("Increment the 2 added items")
                        let moreInventoryItem1 = InventoryItem(quantity: 10, product: product1, inventory: addedInventory)
                        let moreInventoryItem2 = InventoryItem(quantity: 30, product: product2, inventory: addedInventory)
                        let moreInventoryItemWithHistory1 = InventoryItemWithHistoryEntry(inventoryItem: moreInventoryItem1, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                        let moreInventoryItemWithHistory2 = InventoryItemWithHistoryEntry(inventoryItem: moreInventoryItem2, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: DBSharedUser(email: TestUtils.userInput1.email))
                        TestInventory.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [moreInventoryItemWithHistory1, moreInventoryItemWithHistory2]) {result in
                            expect(result.success).to(beTrue())
                            expect(result.successResult).to(beNil())
                            
                            print("Get items")
                            TestInventory.remoteInventoryItemsProvider.inventoryItems(addedInventory) {result in
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
    
    
    func testSyncInventoriesWithItems() {
        
        let expectation = self.expectationWithDescription("add inventory items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak expectation] loginData in
            
            // Simulate a local database
            let inventory1 = Inventory(uuid: NSUUID().UUIDString, name: "myinventory1")
            let inventory2 = Inventory(uuid: NSUUID().UUIDString, name: "myinventory2")
            let inventory3 = Inventory(uuid: NSUUID().UUIDString, name: "myinventory3", removed: true) // this is expected to have no effect because the list hasn't been added to the server yet
            
            let product1 = Product(uuid: NSUUID().UUIDString, name: "myproduct1", price: 1.1)
            let product2 = Product(uuid: NSUUID().UUIDString, name: "myproduct2", price: 2.2)
            let product3 = Product(uuid: NSUUID().UUIDString, name: "myproduct3", price: 3.3)
            
            let inventoryItem1 = InventoryItem(quantity: 0, quantityDelta: 1, product: product1, inventory: inventory1)
            let inventoryItem2 = InventoryItem(quantity: 0, quantityDelta: 2, product: product2, inventory: inventory1)
            let inventoryItem3 = InventoryItem(quantity: 0, quantityDelta: 3, product: product3, inventory: inventory2)
            
            let inventoriesSync = SyncUtils.toInventoriesSync([inventory1, inventory2, inventory3], dbInventoryItems: [inventoryItem1, inventoryItem2, inventoryItem3])
            
            // 1. Very basic sync - remote database is empty
            TestInventory.remoteInventoryProvider.syncInventoriesWithInventoryItems(inventoriesSync) {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let syncResult = result.successResult {
                    
                    expect(syncResult.inventories.count) == 2
                    expect(syncResult.couldNotDelete.count) == 0 // trying to remove a not existing element doesn't count as couldNotDelete
                    expect(syncResult.couldNotUpdate.count) == 0
                    expect(syncResult.inventoryItemsSyncResults.count) == 2 // listitems for 2 lists
                    
                    let remoteInventory1 = syncResult.inventories[0]
                    let remoteInventory2 = syncResult.inventories[1]
                    
                    TestUtils.testRemoteInventoryMatches(remoteInventory1, inventory1)
                    TestUtils.testRemoteInventoryMatches(remoteInventory2, inventory2)
                    
                    let inventoryItemsSyncResult1 = syncResult.inventoryItemsSyncResults[0]
                    let inventoryItemsSyncResult2 = syncResult.inventoryItemsSyncResults[1]
                    
                    expect(inventoryItemsSyncResult1.inventoryUuid == inventory1.uuid)
                    expect(inventoryItemsSyncResult2.inventoryUuid == inventory2.uuid)
                    
                    expect(inventoryItemsSyncResult1.inventoryItems.count) == 2
                    expect(inventoryItemsSyncResult2.inventoryItems.count) == 1
                    
                    let remoteInventoryItem1 = inventoryItemsSyncResult1.inventoryItems[0]
                    let remoteInventoryItem2 = inventoryItemsSyncResult1.inventoryItems[1]
                    let remoteInventoryItem3 = inventoryItemsSyncResult2.inventoryItems[0]
                    
                    TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem1, inventoryItem1)
                    TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem2, inventoryItem2)
                    TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem3, inventoryItem3)
                    
                    expect(inventoryItemsSyncResult1.couldNotDelete).to(beEmpty())
                    expect(inventoryItemsSyncResult2.couldNotDelete).to(beEmpty())
//                    expect(inventoryItemsSyncResult1.couldNotUpdate).to(beEmpty())
//                    expect(inventoryItemsSyncResult2.couldNotUpdate).to(beEmpty())
                    

                    // 2. More complicated sync, list update, list invalid update, listitem update, listitem invalid update, listitem marked as delete
                    let updatedInventory1 = Inventory(uuid: inventory1.uuid, name: "myinventory1-updated", lastServerUpdate: syncResult.inventories[0].lastUpdate) // valid update (== timestamp in server)
                    let updatedInventory2 = Inventory(uuid: inventory2.uuid, name: "myinventory2-updated", lastServerUpdate: NSDate(timeIntervalSinceNow: -3600)) // invalid update
                    
                    let updatedInventoryItem1 = InventoryItem(quantity: remoteInventoryItem1.inventoryItem.quantity, quantityDelta: 1, product: inventoryItem1.product, inventory: inventoryItem1.inventory, lastServerUpdate: remoteInventoryItem1.lastUpdate)
                    
//                    let updatedInventoryItem1 = InventoryItem(uuid: inventoryItem1.uuid, done: false, quantity: 111, product: listItem1.product, section: listItem1.section, list: listItem1.list, order: listItem1.order, lastServerUpdate: remoteListItem1.lastUpdate) // valid update (== timestamp in server)
                    let updatedInventoryItem2 = InventoryItem(quantity: remoteInventoryItem2.inventoryItem.quantity, quantityDelta: 2, product: inventoryItem2.product, inventory: inventoryItem2.inventory, lastServerUpdate: NSDate(timeIntervalSinceNow: -3600)) // invalid update DIFFERENCE TO LISTITEMS: update date for inventory items is ignored, so there's always overwrite (because with quantity increment logic too complex for now). Note this only applies for inventory items not inventories.
                    let updatedInventoryItem3 = InventoryItem(quantity: remoteInventoryItem3.inventoryItem.quantity, quantityDelta: 3, product: inventoryItem3.product, inventory: inventoryItem3.inventory, lastServerUpdate: remoteInventoryItem3.lastUpdate, removed: true) // to delete
                    
                    let inventoriesSync = SyncUtils.toInventoriesSync([updatedInventory1, updatedInventory2], dbInventoryItems: [updatedInventoryItem1, updatedInventoryItem2, updatedInventoryItem3])
                    
                    TestInventory.remoteInventoryProvider.syncInventoriesWithInventoryItems(inventoriesSync) {result in
                        
                        expect(result.success).to(beTrue())
                        expect(result.successResult).toNot(beNil())
                        
                        if let syncResult = result.successResult {
                            
                            expect(syncResult.inventories.count) == 2 // there are still 2 lists in the remote database
                            expect(syncResult.couldNotDelete.count) == 0
                            expect(syncResult.couldNotUpdate.count) == 1
                            expect(syncResult.inventoryItemsSyncResults.count) == 2 // listitems for 2 lists
                            
                            let remoteInventory1 = syncResult.inventories[0]
                            let remoteInventory2 = syncResult.inventories[1]
                            
                            TestUtils.testRemoteInventoryMatches(remoteInventory1, updatedInventory1)
                            TestUtils.testRemoteInventoryMatches(remoteInventory2, inventory2) // the update was invalid, so list should be unchanged
                            
                            let inventoryItemsSyncResult1 = syncResult.inventoryItemsSyncResults[0]
                            let inventoryItemsSyncResult2 = syncResult.inventoryItemsSyncResults[1]
                            
                            expect(inventoryItemsSyncResult1.inventoryUuid == inventory1.uuid)
                            expect(inventoryItemsSyncResult2.inventoryUuid == inventory2.uuid)
                            
                            expect(inventoryItemsSyncResult1.inventoryItems.count) == 2
                            expect(inventoryItemsSyncResult2.inventoryItems.count) == 0 // we removed the only listitem in list2
                            
                            let remoteInventoryItem1 = inventoryItemsSyncResult1.inventoryItems[0]
                            let remoteInventoryItem2 = inventoryItemsSyncResult1.inventoryItems[1]
                            
                            TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem1, updatedInventoryItem1)
                            TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem2, updatedInventoryItem2) // the update was invalid, but for inventory items this is ignored, so update works
                            
                            expect(inventoryItemsSyncResult1.couldNotDelete).to(beEmpty())
                            expect(inventoryItemsSyncResult2.couldNotDelete).to(beEmpty())
//                            expect(listItemsSyncResult1.couldNotUpdate.count) == 1 // there was one item in list1 with an invalid update
//                            expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())
                            
//                             3. Test invalid list delete and a non-changed other lists and list items
                            let updatedAgainInventory1 = Inventory(uuid: inventory1.uuid, name: "myinventory1-updated", lastServerUpdate: NSDate(timeIntervalSinceNow: -3600), removed: true) // invalid update (== timestamp in server)
                            
                            let inventoriesSync = SyncUtils.toInventoriesSync([updatedAgainInventory1], dbInventoryItems: [])
                            
                            TestInventory.remoteInventoryProvider.syncInventoriesWithInventoryItems(inventoriesSync) {result in
                                
                                expect(result.success).to(beTrue())
                                expect(result.successResult).toNot(beNil())
                                
                                if let syncResult = result.successResult {
                                    
                                    expect(syncResult.inventories.count) == 2 // there are still 2 lists in the remote database
                                    expect(syncResult.couldNotDelete.count) == 1 // one invalid delete
                                    expect(syncResult.couldNotUpdate.count) == 0
                                    expect(syncResult.inventoryItemsSyncResults.count) == 2 // still 2 listitems, for 2 lists
                                    
                                    let remoteInventory1 = syncResult.inventories[0]
                                    let remoteInventory2 = syncResult.inventories[1]
                                    
                                    TestUtils.testRemoteInventoryMatches(remoteInventory1, updatedInventory1)
                                    TestUtils.testRemoteInventoryMatches(remoteInventory2, inventory2)
                                    
                                    let inventoryItemsSyncResult1 = syncResult.inventoryItemsSyncResults[0]
                                    let inventoryItemsSyncResult2 = syncResult.inventoryItemsSyncResults[1]
                                    
                                    expect(inventoryItemsSyncResult1.inventoryUuid == inventory1.uuid)
                                    expect(inventoryItemsSyncResult2.inventoryUuid == inventory2.uuid)
                                    
                                    expect(inventoryItemsSyncResult1.inventoryItems.count) == 2
                                    expect(inventoryItemsSyncResult2.inventoryItems.count) == 0
                                    
                                    let remoteInventoryItem1 = inventoryItemsSyncResult1.inventoryItems[0]
                                    let remoteInventoryItem2 = inventoryItemsSyncResult1.inventoryItems[1]
                                    
                                    TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem1, updatedInventoryItem1)
                                    TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem2, updatedInventoryItem2)
                                    
                                    expect(inventoryItemsSyncResult1.couldNotDelete).to(beEmpty())
                                    expect(inventoryItemsSyncResult2.couldNotDelete).to(beEmpty())
//                                    expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
//                                    expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())


                                    // 4. Update (only) a list item - the server will update the lastUpdate timestamp from the list, matching the one from listitem (TODO server)
                                    let updatedAgainInventoryItem2 = InventoryItem(quantity: remoteInventoryItem2.inventoryItem.quantity, quantityDelta: 2222, product: inventoryItem2.product, inventory: inventoryItem2.inventory, lastServerUpdate: NSDate(timeIntervalSinceNow: -3600)) // invalid update DIFFERENCE TO LISTITEMS: update date for inventory items is ignored, so there's always overwrite (because with quantity increment logic too complex for now). Note this only applies for inventory items not inventories.
                                    
                                    let inventoriesSync = SyncUtils.toInventoriesSync([], dbInventoryItems: [updatedAgainInventoryItem2])
                                    
                                    TestInventory.remoteInventoryProvider.syncInventoriesWithInventoryItems(inventoriesSync) {result in
                                        
                                        expect(result.success).to(beTrue())
                                        expect(result.successResult).toNot(beNil())
                                        
                                        if let syncResult = result.successResult {
                                            
                                            expect(syncResult.inventories.count) == 2 // there are still 2 lists in the remote database
                                            expect(syncResult.couldNotDelete.count) == 0
                                            expect(syncResult.couldNotUpdate.count) == 0
                                            expect(syncResult.inventoryItemsSyncResults.count) == 2 // still 2 listitems, for 2 lists
                                            
                                            let remoteInventory1 = syncResult.inventories[0]
                                            let remoteInventory2 = syncResult.inventories[1]
                                            
                                            TestUtils.testRemoteInventoryMatches(remoteInventory1, updatedInventory1)
                                            TestUtils.testRemoteInventoryMatches(remoteInventory2, inventory2)
                                            
                                            let inventoryItemsSyncResult1 = syncResult.inventoryItemsSyncResults[0]
                                            let inventoryItemsSyncResult2 = syncResult.inventoryItemsSyncResults[1]
                                            
                                            expect(inventoryItemsSyncResult1.inventoryUuid == inventory1.uuid)
                                            expect(inventoryItemsSyncResult2.inventoryUuid == inventory2.uuid)
                                            
                                            expect(inventoryItemsSyncResult1.inventoryItems.count) == 2
                                            expect(inventoryItemsSyncResult2.inventoryItems.count) == 0
                                            
                                            let remoteInventoryItem1 = inventoryItemsSyncResult1.inventoryItems[0]
                                            let remoteInventoryItem2 = inventoryItemsSyncResult1.inventoryItems[1]
                                            
                                            TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem1, updatedInventoryItem1)
                                            TestUtils.testRemoteInventoryItemMatches(remoteInventoryItem2, updatedInventoryItem2)
                                            
                                            expect(inventoryItemsSyncResult1.couldNotDelete).to(beEmpty())
                                            expect(inventoryItemsSyncResult2.couldNotDelete).to(beEmpty())
//                                            expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
//                                            expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())
                                            expectation?.fulfill()
                                            // TODO after server change, test lastUpdate list1 == lastUpdate remoteListItem2
                                            
                                            
//                                            // 5. Delete list1 - the list items also have to be deleted
                                            let updatedOnceAgainInventory1 = Inventory(uuid: inventory1.uuid, name: "myinventory1-updated", lastServerUpdate: remoteInventory1.lastUpdate, removed: true)
                                            // Try to update listitem from list1 - here nothing will happen, since list is deleted (not expected to be in cannotUpdate)
                                            let updatedAgainInventoryItem1 = InventoryItem(quantity: remoteInventoryItem2.inventoryItem.quantity, quantityDelta: 1234, product: inventoryItem1.product, inventory: inventoryItem1.inventory, lastServerUpdate: remoteInventoryItem1.lastUpdate) // valid update (== timestamp in server)

                                            let inventoriesSync = SyncUtils.toInventoriesSync([updatedOnceAgainInventory1], dbInventoryItems: [updatedAgainInventoryItem1])
                                            
                                            TestInventory.remoteInventoryProvider.syncInventoriesWithInventoryItems(inventoriesSync) {result in
                                                
                                                expect(result.success).to(beTrue())
                                                expect(result.successResult).toNot(beNil())
                                                
                                                if let syncResult = result.successResult {
                                                    
                                                    expect(syncResult.inventories.count) == 1 // list was deleted
                                                    expect(syncResult.couldNotDelete.count) == 0
                                                    expect(syncResult.couldNotUpdate.count) == 0
                                                    expect(syncResult.inventoryItemsSyncResults.count) == 1 // only one list left - only group of listitems
                                                    
                                                    let remoteInventory1 = syncResult.inventories[0]
                                                    
                                                    TestUtils.testRemoteInventoryMatches(remoteInventory1, inventory2)
                                                    
                                                    let inventoryItemsSyncResult1 = syncResult.inventoryItemsSyncResults[0]
                                                    
                                                    expect(inventoryItemsSyncResult1.inventoryUuid == inventory2.uuid)
                                                    
                                                    expect(inventoryItemsSyncResult1.inventoryItems.count) == 0
                                                    
                                                    expect(inventoryItemsSyncResult1.couldNotDelete).to(beEmpty())
//                                                    expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
                                                    
                                                    expectation?.fulfill()
                                                    
                                                } else {
                                                    expectation?.fulfill()
                                                }
                                                
                                            } // end test 5
                                            
                                            
                                        } else {
                                            expectation?.fulfill()
                                        }
                                        
                                    } // end test 4
                                    
                                    
                                } else {
                                    expectation?.fulfill()
                                }
                                
                            } // end test 3
                            
                            
                        } else {
                            expectation?.fulfill()
                        }
                    } // end test 2
                    
                    
                } else {
                    expectation?.fulfill()
                }
                
            } // end test 1
        }
        
        self.waitForExpectationsWithTimeout(50.0, handler: nil)
    }
}
