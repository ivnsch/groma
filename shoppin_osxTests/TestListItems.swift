//
//  TestListItems.swift
//  shoppin
//
//  Created by ischuetz on 20/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import XCTest
import Nimble

class TestListItems: XCTestCase {
    
    let timeout: NSTimeInterval = 5.0
    
    let remoteProvider = RemoteListItemProvider()
    let remoteUserProvider = RemoteUserProvider()
    
    func testAddListItem() {
        
        let expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1AndAddedList1 {[weak expectation] (loginData, list) in
            
            self.remoteProvider.add(TestUtils.listInput1) {result in
                expect(result.success).to(beTrue())
                
                print("add first list item")
                
                let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
                let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
                let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
                
                self.remoteProvider.add(firstListItem, handler: {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).to(beNil())
                    
                    expectation?.fulfill()
                })
            }
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    
    func testAddListItems() {
        
        let expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1AndAddedList1 {[weak expectation] (loginData, list) in
            
            self.remoteProvider.add(TestUtils.listInput1) {result in
                expect(result.success).to(beTrue())
                
                print("add first list item")
                
                let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
                let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
                let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
                
                self.remoteProvider.add(firstListItem, handler: {[weak expectation] result in
                    expect(result.success).to(beTrue())
                    
                    if result.success {
                        
                        print("add second list item")
                        let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                        let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                        let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: TestUtils.listInput1, order: 2)
                        self.remoteProvider.add(secondListItem, handler: {result in
                            expect(result.success).to(beTrue())
                            expect(result.successResult).to(beNil())
                            
                            if result.success {
                                
                                print("test lists are returned in GET, in correct order")
                                self.remoteProvider.listItems(list: TestUtils.listInput1) {result in
                                    expect(result.success).to(beTrue())
                                    
                                    if let remoteListItems = result.successResult {
                                        
                                        TestUtils.testRemoteListItemsValid(remoteListItems)
                                        
                                        expect(remoteListItems.products.count) == 2

                                        expect(remoteListItems.sections.count) == 2
                                        expect(remoteListItems.listItems.count) == 2
                                        
                                        let product1 = remoteListItems.products[0]
                                        let product2 = remoteListItems.products[1]
                                        
                                        let section1 = remoteListItems.sections[0]
                                        let section2 = remoteListItems.sections[1]
                                        
                                        
                                        let listItem1 = remoteListItems.listItems[0]
                                        let listItem2 = remoteListItems.listItems[1]
                                        
                                        TestUtils.testRemoteProductMatches(product1, firstProduct)
                                        TestUtils.testRemoteProductMatches(product2, secondProduct)
                                        
                                        TestUtils.testRemoteSectionMatches(section1, firstSection)
                                        TestUtils.testRemoteSectionMatches(section2, secondSection)
                                        
                                        TestUtils.testRemoteListItemMatches(listItem1, firstListItem)
                                        TestUtils.testRemoteListItemMatches(listItem2, secondListItem)
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
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func testDeleteListItem() {
        
        let expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1AndAddedList1 {[weak expectation] (loginData, list) in
            
            self.remoteProvider.add(TestUtils.listInput1) {result in
                expect(result.success).to(beTrue())
                
                print("add first list item")
                
                let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
                let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
                let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
                
                self.remoteProvider.add(firstListItem, handler: {result in
                    expect(result.success).to(beTrue())
                    
                    if result.success {
                        
                        print("add second list item")
                        let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                        let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                        let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: TestUtils.listInput1, order: 2)
                        self.remoteProvider.add(secondListItem, handler: {result in
                            expect(result.success).to(beTrue())
                            
                            if result.success {
                                
                                print("remove first list item")
                                self.remoteProvider.remove(firstListItem, handler: {result in
                                    expect(result.success).to(beTrue())
                                    
                                    print("test GET - only second list item should be there")
                                    self.remoteProvider.listItems(list: TestUtils.listInput1) {result in
                                        expect(result.success).to(beTrue())
                                        
                                        if let remoteListItems = result.successResult {
                                            
                                            TestUtils.testRemoteListItemsValid(remoteListItems)
                                            
                                            // removing list item doesn't remove any of the relations (product, list, section) in the remote database but the service returns only relations pertinent to the returned list items, so should be 1 everywhere
                                            expect(remoteListItems.products.count) == 1
                                            expect(remoteListItems.sections.count) == 1
                                            expect(remoteListItems.listItems.count) == 1
                                            
                                            let product = remoteListItems.products[0]
                                            
                                            let section = remoteListItems.sections[0]
                                            
                                            let listItem = remoteListItems.listItems[0]
                                            
                                            TestUtils.testRemoteProductMatches(product, secondProduct)
                                            
                                            TestUtils.testRemoteSectionMatches(section, secondSection)
                                            
                                            TestUtils.testRemoteListMatches(list, TestUtils.listInput1)
                                            //                                        TestUtils.testRemoteListMatches(list, secondList)
                                            
                                            TestUtils.testRemoteListItemMatches(listItem, secondListItem)
                                        }
                                        
                                        expectation?.fulfill()
                                    }
                                    
                                })
                                // TODO test that the product, list, and section of removed list item still exist in remote db
                                
                                
                            } else {
                                expectation?.fulfill()
                            }
                        })
                        
                    } else {
                        expectation?.fulfill()
                    }
                })
            }
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    func testUpdateListItem() {
        
        let expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1AndAddedList1 {[weak expectation] (loginData, list) in
            
            self.remoteProvider.add(TestUtils.listInput1) {result in
                expect(result.success).to(beTrue())
                
                print("add first list item")
                let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
                let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
                let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
                
                self.remoteProvider.add(firstListItem, handler: {[weak expectation] result in
                    expect(result.success).to(beTrue())
                    
                    if result.success {
                        
                        print("add second list item")
                        let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                        let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                        let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: TestUtils.listInput1, order: 2)
                        self.remoteProvider.add(secondListItem, handler: {result in
                            expect(result.success).to(beTrue())
                            
                            if result.success {
                                
                                print("update first list item")
                                // TODO update relations here how handle??
                                let updatedFirstProduct = Product(uuid: firstProduct.uuid, name: "my-first-product-updated", price: 10.01)
                                
                                // TODO test this? - what happens if the client sends same uuid in update - meaning to update this section instead of insertIfNotExists
                                //                            let updatedFirstSection = Section(uuid: firstSection.uuid, name: "my-first-section-updated")
                                //                            let updatedFirstList = List(uuid: firstList.uuid, name: "my-first-list-updated")
                                let updatedFirstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section-new")
                                //                            let updatedFirstList = List(uuid: NSUUID().UUIDString, name: "my-first-list-new")
                                //
                                let updatedFirstListItem = ListItem(uuid: firstListItem.uuid, done: true, quantity: 5, product: updatedFirstProduct, section: updatedFirstSection, list: TestUtils.listInput1, order: 5)
                                
                                self.remoteProvider.update(updatedFirstListItem, handler: {result in
                                    expect(result.success).to(beTrue())
                                    
                                    print("test item was updated correctly")
                                    self.remoteProvider.listItems(list: TestUtils.listInput1) {result in
                                        expect(result.success).to(beTrue())
                                        expect(result.successResult).toNot(beNil())
                                        
                                        if let remoteListItems = result.successResult {
                                            
                                            TestUtils.testRemoteListItemsValid(remoteListItems)
                                            
                                            expect(remoteListItems.products.count) == 2
                                            //                                        expect(remoteListItems.lists.count) == 2
                                            expect(remoteListItems.sections.count) == 2 // changing the list item's section adds a new one (if one with that name doesn't exist yet)
                                            expect(remoteListItems.listItems.count) == 2
                                            
                                            let product1 = remoteListItems.products[0]
                                            let product2 = remoteListItems.products[1]

                                            let section1 = remoteListItems.sections[0]
                                            let section2 = remoteListItems.sections[1]

                                            
                                            let listItem1 = remoteListItems.listItems[0]
                                            let listItem2 = remoteListItems.listItems[1]
                                            
                                            TestUtils.testRemoteProductMatches(product1, updatedFirstProduct)
                                            TestUtils.testRemoteProductMatches(product2, secondProduct)
                                            
                                            // since we send new section and list, the previous second will be first and new one second. (the previous first doesn't appear in the result as it's not used by returned listitems)
                                            TestUtils.testRemoteSectionMatches(section2, updatedFirstSection)
                                            TestUtils.testRemoteSectionMatches(section1, secondSection)

                                            TestUtils.testRemoteListItemMatches(listItem1, updatedFirstListItem)
                                            TestUtils.testRemoteListItemMatches(listItem2, secondListItem)
                                        }
                                        
                                        expectation?.fulfill()
                                    }
                                })
                                
                                
                                
                            } else {
                                expectation?.fulfill()
                            }
                        })
                        
                    } else {
                        expectation?.fulfill()
                    }
                })
            }
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    
    func testListItemsSync() {
        let expectation = self.expectationWithDescription("Sync inventories")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            // Simulate a local database: 1 list, 3 products, 2 sections, 3 listitems
            let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 1.1)
            let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 2.2)
            let thirdProduct = Product(uuid: NSUUID().UUIDString, name: "my-third-product", price: 3.3)
            let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
            let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
            let listItem1 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 11, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
            let listItem2 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 22, product: secondProduct, section: firstSection, list: TestUtils.listInput1, order: 1)
            let listItem3 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 33, product: thirdProduct, section: secondSection, list: TestUtils.listInput1, order: 1)

            self!.remoteProvider.add(TestUtils.listInput1) {result in
                expect(result.success).to(beTrue())
            
                // Part 1. add 2 first items and try to remove the last one. We expect adding to succeed and the removal to be ignored
                self!.remoteProvider.syncListItems (TestUtils.listInput1, listItems: [listItem1, listItem2], toRemove: [listItem3]) {result in
                    expect(result.success).to(beTrue())
                    expect(result.successResult).toNot(beNil())
                    expect(result.successResult?.items).toNot(beNil())
                    expect(result.successResult?.items.first).toNot(beNil())
                    expect(result.successResult?.items.count) == 1
                    

                    if let result = result.successResult, listItemsWithRelations = result.items.first {
                        
                        expect(listItemsWithRelations.listItems.count) == 2
                        expect(result.couldNotUpdate.count) == 0
                        expect(result.couldNotDelete.count) == 0 // item is couldNotDelete only when it was not possible to delete due to a conflict in the server (there's another version of the item). Trying to delete an item that doesn't exist in the server is ignored
                        
                        TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[0], listItem1)
                        TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[1], listItem2)
                        
                        // Part 2. Update listItem1, delete listItem2 and add listItem3
                        // Note that for now we send always the complete database - TODO implement or test that we send only added/modified
                        let updatedListItem1 = ListItem(uuid: listItem1.uuid, done: false, quantity: 111, product: firstProduct, section: firstSection, list: TestUtils.listInput1, order: 1, lastServerUpdate: listItemsWithRelations.listItems[0].lastUpdate)
                        let updatedListItem2 = ListItem(uuid: listItem2.uuid, done: listItem2.done, quantity: listItem2.quantity, product: listItem2.product, section: listItem2.section, list: TestUtils.listInput1, order: listItem2.order, lastServerUpdate: listItemsWithRelations.listItems[1].lastUpdate)
                        
                        self!.remoteProvider.syncListItems(TestUtils.listInput1, listItems: [updatedListItem1, listItem3], toRemove: [updatedListItem2]) {result in
                            expect(result.success).to(beTrue())
                            expect(result.successResult).toNot(beNil())
                            expect(result.successResult?.items).toNot(beNil())
                            expect(result.successResult?.items.first).toNot(beNil())
                            expect(result.successResult?.items.count) == 1
                            
                            if let result = result.successResult, listItemsWithRelations = result.items.first {
                                
                                expect(listItemsWithRelations.listItems.count) == 2
                                expect(result.couldNotUpdate.count) == 0
                                expect(result.couldNotDelete.count) == 0 // item is couldNotDelete only when it was not possible to delete due to a conflict in the server (there's another version of the item). Trying to delete an item that doesn't exist in the server is ignored
                                
                                TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[0], updatedListItem1)
                                TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[1], listItem3)
                                

                                // Part 3. Try an update with an out of sync item (last server update date is older than in the server) and a synched item (last server update date is the same as in server)
                                let outOfSyncListItem1 = ListItem(uuid: listItem1.uuid, done: listItem1.done, quantity: 123456, product: listItem1.product, section: listItem1.section, list: TestUtils.listInput1, order: listItem1.order, lastServerUpdate: NSDate(timeIntervalSinceNow: -3600))
                                
                                let updatedListItem3 = ListItem(uuid: listItem3.uuid, done: true, quantity: 567, product: listItem3.product, section: listItem3.section, list: TestUtils.listInput1, order: listItem3.order, lastServerUpdate: listItemsWithRelations.listItems[1].lastUpdate)
                                
                                
                                self!.remoteProvider.syncListItems(TestUtils.listInput1, listItems: [outOfSyncListItem1, updatedListItem3], toRemove: []) {result in
                                    expect(result.success).to(beTrue())
                                    expect(result.successResult).toNot(beNil())
                                    expect(result.successResult?.items).toNot(beNil())
                                    expect(result.successResult?.items.first).toNot(beNil())
                                    expect(result.successResult?.items.count) == 1
                                    
                                    if let result = result.successResult, listItemsWithRelations = result.items.first {
                                        
                                        expect(listItemsWithRelations.listItems.count) == 2
                                        expect(result.couldNotUpdate.count) == 1
                                        expect(result.couldNotDelete.count) == 0 // item is couldNotDelete only when it was not possible to delete due to a conflict in the server (there's another version of the item). Trying to delete an item that doesn't exist in the server is ignored
                                        
                                        TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[0], updatedListItem1)
                                        TestUtils.testRemoteListItemMatches(listItemsWithRelations.listItems[1], updatedListItem3)
                                        
                                        expect(result.couldNotUpdate[0] == outOfSyncListItem1.uuid)
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
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
}
