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
    
    let remoteProvider = RemoteListItemProvider()

    func testAddListItem() {
        
        var expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearedDatabase(self.remoteProvider) {
            
            println("add first list item")
            
            let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
            let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
            let firstList = List(uuid: NSUUID().UUIDString, name: "my-first-list")
            let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: firstList, order: 1)
            
            self.remoteProvider.add(firstListItem, handler: {try in
                expect(try.success).toNot(beNil())
                
                if let remoteListItem = try.success {
                    println("test first list item is returned correctly")
                    TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                    TestUtils.testRemoteListItemWithDataMatches(remoteListItem, firstListItem)
                    
                }
                
                expectation.fulfill()
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testAddListItems() {
        
        var expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearedDatabase(self.remoteProvider) {
            
            println("add first list item")
            
            let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
            let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
            let firstList = List(uuid: NSUUID().UUIDString, name: "my-first-list")
            let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: firstList, order: 1)
            
            self.remoteProvider.add(firstListItem, handler: {try in
                expect(try.success).toNot(beNil())
                
                if let remoteListItem = try.success {
                    println("test first list item is returned correctly")
                    TestUtils.testRemoteListItemWithDataMatches(remoteListItem, firstListItem)
                    
                    println("add second list item")
                    let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                    let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "my-second-list")
                    let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: secondList, order: 2)
                    self.remoteProvider.add(secondListItem, handler: {try in
                        expect(try.success).toNot(beNil())
                        
                        if let remoteListItem = try.success {
                            println("test second list item is returned correctly")
                            TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                            TestUtils.testRemoteListItemWithDataMatches(remoteListItem, secondListItem)
                            
                            println("test lists are returned in GET, in correct order")
                            self.remoteProvider.listItems {try in
                                expect(try.success).toNot(beNil())
                                
                                if let remoteListItems = try.success {
                                    
                                    TestUtils.testRemoteListItemsValid(remoteListItems)

                                    expect(remoteListItems.products.count) == 2
                                    expect(remoteListItems.lists.count) == 2
                                    expect(remoteListItems.sections.count) == 2
                                    expect(remoteListItems.listItems.count) == 2
                                    
                                    let product1 = remoteListItems.products[0]
                                    let product2 = remoteListItems.products[1]
                                    
                                    let section1 = remoteListItems.sections[0]
                                    let section2 = remoteListItems.sections[1]
                                    
                                    let list1 = remoteListItems.lists[0]
                                    let list2 = remoteListItems.lists[1]
                                    
                                    let listItem1 = remoteListItems.listItems[0]
                                    let listItem2 = remoteListItems.listItems[1]
                                    
                                    TestUtils.testRemoteProductMatches(product1, firstProduct)
                                    TestUtils.testRemoteProductMatches(product2, secondProduct)
                                    
                                    TestUtils.testRemoteSectionMatches(section1, firstSection)
                                    TestUtils.testRemoteSectionMatches(section2, secondSection)
                                    
                                    TestUtils.testRemoteListMatches(list1, firstList)
                                    TestUtils.testRemoteListMatches(list2, secondList)
                                    
                                    TestUtils.testRemoteListItemMatches(listItem1, firstListItem)
                                    TestUtils.testRemoteListItemMatches(listItem2, secondListItem)
                                }
                                
                                expectation.fulfill()
                            }
                            
                        } else {
                            expectation.fulfill()
                        }
                    })
                    
                } else {
                    expectation.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testDeleteListItem() {
        
        var expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearedDatabase(self.remoteProvider) {
            
            println("add first list item")
            
            let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
            let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
            let firstList = List(uuid: NSUUID().UUIDString, name: "my-first-list")
            let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: firstList, order: 1)
            
            self.remoteProvider.add(firstListItem, handler: {try in
                expect(try.success).toNot(beNil())
                
                if let remoteListItem = try.success {
                    println("test first list item is returned correctly")
                    TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                    TestUtils.testRemoteListItemWithDataMatches(remoteListItem, firstListItem)
                    
                    println("add second list item")
                    let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                    let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "my-second-list")
                    let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: secondList, order: 2)
                    self.remoteProvider.add(secondListItem, handler: {try in
                        expect(try.success).toNot(beNil())
                        
                        if let remoteListItem = try.success {
                            println("test second list item is returned correctly")
                            TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                            TestUtils.testRemoteListItemWithDataMatches(remoteListItem, secondListItem)

                            println("remove first list item")
                            self.remoteProvider.remove(firstListItem, handler: {try in
                                expect(try.success).toNot(beNil())
                                expect(try.success ?? false).to(beTrue())
                                
                                println("test GET - only second list item should be there")
                                self.remoteProvider.listItems {try in
                                    expect(try.success).toNot(beNil())
                                    
                                    if let remoteListItems = try.success {
                                        
                                        TestUtils.testRemoteListItemsValid(remoteListItems)

                                        // removing list item doesn't remove any of the relations (product, list, section) in the remote database but the service returns only relations pertinent to the returned list items, so should be 1 everywhere
                                        expect(remoteListItems.products.count) == 1
                                        expect(remoteListItems.lists.count) == 1
                                        expect(remoteListItems.sections.count) == 1
                                        expect(remoteListItems.listItems.count) == 1
                                        
                                        let product = remoteListItems.products[0]
                                        
                                        let section = remoteListItems.sections[0]
                                        
                                        let list = remoteListItems.lists[0]
                                        
                                        let listItem = remoteListItems.listItems[0]
                                        
                                        TestUtils.testRemoteProductMatches(product, secondProduct)
                                        
                                        TestUtils.testRemoteSectionMatches(section, secondSection)
                                        
                                        TestUtils.testRemoteListMatches(list, secondList)
                                        
                                        TestUtils.testRemoteListItemMatches(listItem, secondListItem)
                                    }
                                    
                                    expectation.fulfill()
                                }

                            })
                                // TODO test that the product, list, and section of removed list item still exist in remote db

                            
                        } else {
                            expectation.fulfill()
                        }
                    })
                    
                } else {
                    expectation.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testUpdateListItem() {
        
        var expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearedDatabase(self.remoteProvider) {
            
            println("add first list item")
            
            let firstProduct = Product(uuid: NSUUID().UUIDString, name: "my-first-product", price: 3.5)
            let firstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section")
            let firstList = List(uuid: NSUUID().UUIDString, name: "my-first-list")
            let firstListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: firstProduct, section: firstSection, list: firstList, order: 1)
            
            self.remoteProvider.add(firstListItem, handler: {try in
                expect(try.success).toNot(beNil())
                
                if let remoteListItem = try.success {
                    println("test first list item is returned correctly")
                    TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                    TestUtils.testRemoteListItemWithDataMatches(remoteListItem, firstListItem)
                    
                    println("add second list item")
                    let secondProduct = Product(uuid: NSUUID().UUIDString, name: "my-second-product", price: 3.5)
                    let secondSection = Section(uuid: NSUUID().UUIDString, name: "my-second-section")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "my-second-list")
                    let secondListItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: secondProduct, section: secondSection, list: secondList, order: 2)
                    self.remoteProvider.add(secondListItem, handler: {try in
                        expect(try.success).toNot(beNil())
                        
                        if let remoteListItem = try.success {
                            println("test second list item is returned correctly")
                            TestUtils.testRemoteListItemWithDataValid(remoteListItem)
                            TestUtils.testRemoteListItemWithDataMatches(remoteListItem, secondListItem)
                            
                            println("update first list item")
                            // TODO update relations here how handle??
                            let updatedFirstProduct = Product(uuid: firstProduct.uuid, name: "my-first-product-updated", price: 10.01)
                            
                            // TODO test this? - what happens if the client sends same uuid in update - meaning to update this section instead of insertIfNotExists
//                            let updatedFirstSection = Section(uuid: firstSection.uuid, name: "my-first-section-updated")
//                            let updatedFirstList = List(uuid: firstList.uuid, name: "my-first-list-updated")
                            let updatedFirstSection = Section(uuid: NSUUID().UUIDString, name: "my-first-section-new")
                            let updatedFirstList = List(uuid: NSUUID().UUIDString, name: "my-first-list-new")
                            
                            let updatedFirstListItem = ListItem(uuid: firstListItem.uuid, done: true, quantity: 5, product: updatedFirstProduct, section: updatedFirstSection, list: updatedFirstList, order: 5)
                            
                            self.remoteProvider.update(updatedFirstListItem, handler: {try in
                                expect(try.success).toNot(beNil())
                                expect(try.success ?? false).to(beTrue())
                                
                                println("test GET - only second list item should be there")
                                self.remoteProvider.listItems {try in
                                    expect(try.success).toNot(beNil())
                                    
                                    if let remoteListItems = try.success {
                                        
                                        TestUtils.testRemoteListItemsValid(remoteListItems)
                                        
                                        expect(remoteListItems.products.count) == 2
                                        expect(remoteListItems.lists.count) == 2
                                        expect(remoteListItems.sections.count) == 2
                                        expect(remoteListItems.listItems.count) == 2
                                        
                                        let product1 = remoteListItems.products[0]
                                        let product2 = remoteListItems.products[1]
                                        
                                        let section1 = remoteListItems.sections[0]
                                        let section2 = remoteListItems.sections[1]
                                        
                                        let list1 = remoteListItems.lists[0]
                                        let list2 = remoteListItems.lists[1]
                                        
                                        let listItem1 = remoteListItems.listItems[0]
                                        let listItem2 = remoteListItems.listItems[1]
                                        
                                        TestUtils.testRemoteProductMatches(product1, updatedFirstProduct)
                                        TestUtils.testRemoteProductMatches(product2, secondProduct)
                                        
                                        // since we send new section and list, the previous second will be first and new one second. (the previous first doesn't appear in the result as it's not used by returned listitems)
                                        TestUtils.testRemoteSectionMatches(section1, secondSection)
                                        TestUtils.testRemoteSectionMatches(section2, updatedFirstSection)
                                        TestUtils.testRemoteListMatches(list1, secondList)
                                        TestUtils.testRemoteListMatches(list2, updatedFirstList)
                                        
                                        TestUtils.testRemoteListItemMatches(listItem1, updatedFirstListItem)
                                        TestUtils.testRemoteListItemMatches(listItem2, secondListItem)
                                    }
                                    
                                    expectation.fulfill()
                                }
                            })
                            
                            
                            
                        } else {
                            expectation.fulfill()
                        }
                    })
                    
                } else {
                    expectation.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
