//
//  TestHistory.swift
//  shoppin
//
//  Created by ischuetz on 14/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestHistory: XCTestCase {
    
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    let remoteHistoryProvider = RemoteHistoryProvider()

    func testAddInventoryItems() {
        let expectation = self.expectationWithDescription("Test that adding inventory items updates history correctly")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            TestInventory.withAddedInventory(expectation) {addedInventory in
                
                print("Add 2 items")
                let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
                let inventoryItem1 = InventoryItem(quantity: 0, quantityDelta: 2, product: product1, inventory: addedInventory)
                let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
                let inventoryItem2 = InventoryItem(quantity: 0, product: product2, inventory: addedInventory)
                let inventoryItemWithHistory1 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem1, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: SharedUser(email: TestUtils.userInput1.email))
                let inventoryItemWithHistory2 = InventoryItemWithHistoryEntry(inventoryItem: inventoryItem2, historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: SharedUser(email: TestUtils.userInput1.email))
                self!.remoteInventoryItemsProvider.addToInventory(addedInventory, inventoryItems: [inventoryItemWithHistory1, inventoryItemWithHistory2]) {result in
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
                            
                            
                            self!.remoteHistoryProvider.historyItems(addedInventory) {result in
                                
                                if let remoteHistoryItems = result.successResult {
                                    let historyItems = remoteHistoryItems.historyItems
                                    let products = remoteHistoryItems.products
                                    let users = remoteHistoryItems.users
                                    
                                    expect(historyItems.count) == 2
                                    expect(products.count) == 2
                                    expect(users.count) == 1
                                    
                                    TestUtils.testHistoryItemMatches(historyItems[0], inventoryItemWithHistory: inventoryItemWithHistory1, remoteHistoryItems: remoteHistoryItems)
                                    TestUtils.testHistoryItemMatches(historyItems[1], inventoryItemWithHistory: inventoryItemWithHistory2, remoteHistoryItems: remoteHistoryItems)
                                    
                                    expectation?.fulfill()
                                }
                            }
                            
                        } else {
                            expectation?.fulfill()
                        }
                    }
                }
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
 
    func testHistorySync() {
        let expectation = self.expectationWithDescription("Test history sync")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            TestInventory.withAddedInventory(expectation) {addedInventory in
                
                //Local database
                let product1 = Product(uuid: NSUUID().UUIDString, name: "tomatoes", price: 2.4)
                let product2 = Product(uuid: NSUUID().UUIDString, name: "bread", price: 0.7)
                // TODO think about not sending inventory in the request (aggregate) is it safe to assume the inventory will be always there?
                // If handling the foreign key exception enough (sending back an error) to cover e.g. concurrent access issues?
                let historyItem1 = HistoryItem(uuid: NSUUID().UUIDString, inventory: TestInventory.inventory1, product: product1, addedDate: NSDate(), quantity: 1, user: SharedUser(email: TestUtils.userInput1.email))
                let historyItem2 = HistoryItem(uuid: NSUUID().UUIDString, inventory: TestInventory.inventory1, product: product2, addedDate: NSDate(), quantity: 2, user: SharedUser(email: TestUtils.userInput1.email))
                
                let historyItemsSync = SyncUtils.toHistoryItemsSync([historyItem1, historyItem2])
                
                self!.remoteHistoryProvider.syncHistoryItems(historyItemsSync)  {result in
                    
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    expect(result.successResult?.items.count ?? 0) == 1
                    
                    if let syncResult = result.successResult, remoteHistoryItems = syncResult.items.first {
                        
                        let historyItems = remoteHistoryItems.historyItems
                        let inventories = remoteHistoryItems.inventories
                        let products = remoteHistoryItems.products
                        let users = remoteHistoryItems.users
                        
                        expect(historyItems.count) == 2
                        expect(inventories.count) == 1
                        expect(products.count) == 2
                        expect(users.count) == 1
                    
                        expect(syncResult.couldNotDelete.count) == 0
                        expect(syncResult.couldNotUpdate.count) == 0
                        
                        TestUtils.testHistoryItemMatches(historyItems[0], historyItem: historyItem1)
                        TestUtils.testHistoryItemMatches(historyItems[1], historyItem: historyItem2)
                        
                        TestUtils.testRemoteProductMatches(products[0], product1)
                        TestUtils.testRemoteProductMatches(products[1], product2)
                        
                        expect(users[0].email) == TestUtils.userInput1.email
                        
                        expectation?.fulfill()
                        // TODO test rest of sync (like in list or inventory items)

                    } else {
                        expectation?.fulfill()
                    }
                }
                
                
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
}