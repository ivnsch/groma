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
        
        let expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstList, handler: {result in
                
                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                if let remoteList = result.successResult {
                    print("test first list is returned correctly")
                    TestUtils.testRemoteListValid(remoteList)
                    TestUtils.testRemoteListMatches(remoteList, firstList)
                    
                    print("add second list")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
                    self.remoteProvider.add(secondList, handler: {result in
                        
                        expect(result.success).to(beTrue())
                        TestUtils.testIfSuccessWithResult(result)
                        
                        if let remoteList = result.successResult {
                            print("test second list is returned correctly")
                            TestUtils.testRemoteListValid(remoteList)
                            TestUtils.testRemoteListMatches(remoteList, secondList)
                            
                            print("test lists are returned in GET, in correct order")
                            self.remoteProvider.lists {result in
                                expect(result.success).toNot(beNil())
                                
                                if let lists = result.successResult {
                                    
                                    expect(lists.count) == 2
                                    
                                    TestUtils.testRemoteListValid(lists[0])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[0], firstList)
                                    TestUtils.testRemoteListValid(lists[1])
                                    TestUtils.testRemoteListWithSharedUsersMatches(lists[1], secondList)
                                    
                                    
                                    print("should get error response when adding a list with a shared user that is not registered")
                                    let thirdList = List(uuid: NSUUID().UUIDString, name: "test-third-list", listItems: [], users: [SharedUser(email: "does@not.exist")])
                                    self.remoteProvider.add(thirdList, handler: {result in
                                        expect(result.success).to(beFalse())
                                        expect(result.successResult).to(beNil())
                                        expect(result.status) == RemoteStatusCode.NotFound // TODO this error has to be improved (*user* not found, and return list of not found users). For now this is all that can be tested
                                        
                                        expectation?.fulfill()
                                     })
                                    
                                } else {
                                    expectation?.fulfill()
                                }
                                
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
    
    
    // TODO adding a list when there's already one should return already exists! right now this returns success with the added list, also add test for this
    
    func testRemoveList() {
        let expectation = self.expectationWithDescription("add lists")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {[weak expectation] loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstList, handler: {result in

                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                print("add second list")
                let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
                self.remoteProvider.add(secondList, handler: {result in

                    expect(result.success).to(beTrue())
                    TestUtils.testIfSuccessWithResult(result)
                    
                    if let remoteList = result.successResult {
                        print("test second list is returned correctly")
                        TestUtils.testRemoteListValid(remoteList)
                        TestUtils.testRemoteListMatches(remoteList, secondList)
                        
                        print("delete first list")
                        self.remoteProvider.remove(firstList, handler: {result in
                            
                            expect(result.success).to(beTrue())
                            
                            print("get lists - should only contain second added one")
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
        let expectation = self.expectationWithDescription("update lists")
        
        self.withAddedLists(expectation) {[weak expectation] (tuple1, tuple2) in
            
            print("update first list")
            let updatedList = List(uuid: tuple1.list.uuid, name: "test-first-list-new-name", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
            // TODO test validtion when we send empty shared users. The server should reject this (it's not implemented yet)
            self.remoteProvider.update(updatedList, handler: {result in
                expect(result.success).to(beTrue())
                expectation?.fulfill()
                
                print("result of POST list: \(result.success), uuid: \(tuple1.list.uuid)")
                
                print("get lists - check update worked")
                self.remoteProvider.lists {result in
                    expect(result.success).toNot(beNil())
                    
                    if let lists = result.successResult {
                        expect(lists.count) == 2
                        TestUtils.testRemoteListValid(lists[0])
                        TestUtils.testRemoteListWithSharedUsersMatches(lists[0], updatedList)
                        TestUtils.testRemoteListValid(lists[1])
                        TestUtils.testRemoteListWithSharedUsersMatches(lists[1], tuple2.list)
                    }
                    
                    expectation?.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    /// Utility method to make tests after successfully added 2 list. Passes 2 pairs to the block containing the list which was sent to the server and the list returned by the server
    private func withAddedLists(expectation: XCTestExpectation?, block: ((list: List, remote: RemoteList), (list: List, remote: RemoteList)) -> ()) {
        
        TestUtils.withClearDatabaseAndNewLoggedInAccount {loginData in
            
            print("add first list")
            let firstList = List(uuid: NSUUID().UUIDString, name: "test-first-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
            self.remoteProvider.add(firstList, handler: {result in
                
                expect(result.success).to(beTrue())
                TestUtils.testIfSuccessWithResult(result)
                
                if let list1 = result.successResult {
                    TestUtils.testRemoteListMatches(list1, firstList)
                    
                    expect(list1.users.count) == 1
                    let user = list1.users.first!
                    expect(user.uuid).toNot(beEmpty())
                    expect(user.email) == loginData.email
                    expect(user.firstName) == TestUtils.userInput1.firstName
                    expect(user.lastName) == TestUtils.userInput1.lastName
                    
                    
                    print("add second list")
                    let secondList = List(uuid: NSUUID().UUIDString, name: "test-second-list", listItems: [], users: [SharedUser(email: TestUtils.userInput1.email)])
                    self.remoteProvider.add(secondList, handler: {result in
                        
                        expect(result.success).to(beTrue())
                        TestUtils.testIfSuccessWithResult(result)
                        
                        print("test second list is returned correctly")
                        if let list2 = result.successResult {
                            TestUtils.testRemoteListWithSharedUsersMatches(list2, secondList)
                            
                            expect(list2.users.count) == 1
                            let user = list2.users.first!
                            expect(user.uuid).toNot(beEmpty())
                            expect(user.email) == loginData.email
                            expect(user.firstName) == TestUtils.userInput1.firstName
                            expect(user.lastName) == TestUtils.userInput1.lastName
                            
                            block((firstList, list1), (secondList, list2))
                            
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
    
    func testSyncListsWithItems() {
        
        let expectation = self.expectationWithDescription("add list items")
        
        TestUtils.withClearDatabaseAndNewLoggedInAccountUser1 {[weak self, weak expectation] loginData in
            
            // Simulate a local database
            let list1 = List(uuid: NSUUID().UUIDString, name: "mylist1")
            let list2 = List(uuid: NSUUID().UUIDString, name: "mylist2")
            let list3 = List(uuid: NSUUID().UUIDString, name: "mylist3", removed: true) // this is expected to have no effect because the list hasn't been added to the server yet
            
            let product1 = Product(uuid: NSUUID().UUIDString, name: "myproduct1", price: 1.1)
            let product2 = Product(uuid: NSUUID().UUIDString, name: "myproduct2", price: 2.2)
            let product3 = Product(uuid: NSUUID().UUIDString, name: "myproduct3", price: 3.3)

            let section1 = Section(uuid: NSUUID().UUIDString, name: "mysection1")
            let section2 = Section(uuid: NSUUID().UUIDString, name: "mysection2")
//            let section3 = Section(uuid: NSUUID().UUIDString, name: "mysection3")
            
            let listItem1 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 1, product: product1, section: section1, list: list1, order: 0)
            let listItem2 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 2, product: product2, section: section1, list: list1, order: 0)
            let listItem3 = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: 3, product: product3, section: section2, list: list2, order: 0)
            
            let listsSync = SyncUtils.toListsSync([list1, list2, list3], dbListItems: [listItem1, listItem2, listItem3])
        
            // 1. Very basic sync - remote database is empty
            self?.remoteProvider.syncListsWithListItems(listsSync) {result in
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                if let syncResult = result.successResult {
                
                    expect(syncResult.lists.count) == 2
                    expect(syncResult.couldNotDelete.count) == 0 // trying to remove a not existing element doesn't count as couldNotDelete
                    expect(syncResult.couldNotUpdate.count) == 0
                    expect(syncResult.listItemsSyncResults.count) == 2 // listitems for 2 lists

                    let remoteList1 = syncResult.lists[0]
                    let remoteList2 = syncResult.lists[1]
                    
                    TestUtils.testRemoteListMatches(remoteList1, list1)
                    TestUtils.testRemoteListMatches(remoteList2, list2)
                    
                    let listItemsSyncResult1 = syncResult.listItemsSyncResults[0]
                    let listItemsSyncResult2 = syncResult.listItemsSyncResults[1]

                    expect(listItemsSyncResult1.listUuid == list1.uuid)
                    expect(listItemsSyncResult2.listUuid == list2.uuid)
                    
                    expect(listItemsSyncResult1.listItems.count) == 2
                    expect(listItemsSyncResult2.listItems.count) == 1
                    
                    let remoteListItem1 = listItemsSyncResult1.listItems[0]
                    let remoteListItem2 = listItemsSyncResult1.listItems[1]
                    let remoteListItem3 = listItemsSyncResult2.listItems[0]
                    
                    TestUtils.testRemoteListItemMatches(remoteListItem1, listItem1)
                    TestUtils.testRemoteListItemMatches(remoteListItem2, listItem2)
                    TestUtils.testRemoteListItemMatches(remoteListItem3, listItem3)
                    
                    expect(listItemsSyncResult1.couldNotDelete).to(beEmpty())
                    expect(listItemsSyncResult2.couldNotDelete).to(beEmpty())
                    expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
                    expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())
                    
                    // 2. More complicated sync, list update, list invalid update, listitem update, listitem invalid update, listitem marked as delete
                    let updatedList1 = List(uuid: list1.uuid, name: "mylist1-updated", lastServerUpdate: syncResult.lists[0].lastUpdate) // valid update (== timestamp in server)
                    let updatedList2 = List(uuid: list2.uuid, name: "mylist2-updated", lastServerUpdate: NSDate(timeIntervalSinceNow: -3600)) // invalid update
                    let updatedListItem1 = ListItem(uuid: listItem1.uuid, done: false, quantity: 111, product: listItem1.product, section: listItem1.section, list: listItem1.list, order: listItem1.order, lastServerUpdate: remoteListItem1.lastUpdate) // valid update (== timestamp in server)
                    let updatedListItem2 = ListItem(uuid: listItem2.uuid, done: listItem2.done, quantity: listItem2.quantity, product: listItem2.product, section: listItem2.section, list: listItem2.list, order: listItem2.order, lastServerUpdate: NSDate(timeIntervalSinceNow: -3600)) // invalid update
                    let updatedListItem3 = ListItem(uuid: listItem3.uuid, done: listItem3.done, quantity: listItem3.quantity, product: listItem3.product, section: listItem3.section, list: listItem3.list, order: listItem3.order, lastServerUpdate: remoteListItem3.lastUpdate, removed: true) // to delete
                    
                    let listsSync = SyncUtils.toListsSync([updatedList1, updatedList2], dbListItems: [updatedListItem1, updatedListItem2, updatedListItem3])
                    
                    self?.remoteProvider.syncListsWithListItems(listsSync) {result in
                        
                        expect(result.success).to(beTrue())
                        expect(result.successResult).toNot(beNil())
                        
                        if let syncResult = result.successResult {
                            
                            expect(syncResult.lists.count) == 2 // there are still 2 lists in the remote database
                            expect(syncResult.couldNotDelete.count) == 0
                            expect(syncResult.couldNotUpdate.count) == 1
                            expect(syncResult.listItemsSyncResults.count) == 2 // listitems for 2 lists
                            
                            let remoteList1 = syncResult.lists[0]
                            let remoteList2 = syncResult.lists[1]
                            
                            TestUtils.testRemoteListMatches(remoteList1, updatedList1)
                            TestUtils.testRemoteListMatches(remoteList2, list2) // the update was invalid, so list should be unchanged
                            
                            let listItemsSyncResult1 = syncResult.listItemsSyncResults[0]
                            let listItemsSyncResult2 = syncResult.listItemsSyncResults[1]
                            
                            expect(listItemsSyncResult1.listUuid == list1.uuid)
                            expect(listItemsSyncResult2.listUuid == list2.uuid)
                            
                            expect(listItemsSyncResult1.listItems.count) == 2
                            expect(listItemsSyncResult2.listItems.count) == 0 // we removed the only listitem in list2
                            
                            let remoteListItem1 = listItemsSyncResult1.listItems[0]
                            let remoteListItem2 = listItemsSyncResult1.listItems[1]
                            
                            TestUtils.testRemoteListItemMatches(remoteListItem1, updatedListItem1)
                            TestUtils.testRemoteListItemMatches(remoteListItem2, listItem2) // the update was invalid, so listitem should be unchanged
                            
                            expect(listItemsSyncResult1.couldNotDelete).to(beEmpty())
                            expect(listItemsSyncResult2.couldNotDelete).to(beEmpty())
                            expect(listItemsSyncResult1.couldNotUpdate.count) == 1 // there was one item in list1 with an invalid update
                            expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())


                            // 3. Test invalid list delete and a non-changed other lists and list items
                            let updatedAgainList1 = List(uuid: list1.uuid, name: "mylist1-updated", lastServerUpdate: NSDate(timeIntervalSinceNow: -3600), removed: true) // invalid update (== timestamp in server)

                            let listsSync = SyncUtils.toListsSync([updatedAgainList1], dbListItems: [])
                            
                            self?.remoteProvider.syncListsWithListItems(listsSync) {result in
                            
                                expect(result.success).to(beTrue())
                                expect(result.successResult).toNot(beNil())
                                
                                if let syncResult = result.successResult {
                                    
                                    expect(syncResult.lists.count) == 2 // there are still 2 lists in the remote database
                                    expect(syncResult.couldNotDelete.count) == 1 // one invalid delete
                                    expect(syncResult.couldNotUpdate.count) == 0
                                    expect(syncResult.listItemsSyncResults.count) == 2 // still 2 listitems, for 2 lists
                                    
                                    let remoteList1 = syncResult.lists[0]
                                    let remoteList2 = syncResult.lists[1]
                                    
                                    TestUtils.testRemoteListMatches(remoteList1, updatedList1)
                                    TestUtils.testRemoteListMatches(remoteList2, list2)

                                    let listItemsSyncResult1 = syncResult.listItemsSyncResults[0]
                                    let listItemsSyncResult2 = syncResult.listItemsSyncResults[1]
                                    
                                    expect(listItemsSyncResult1.listUuid == list1.uuid)
                                    expect(listItemsSyncResult2.listUuid == list2.uuid)
                                    
                                    expect(listItemsSyncResult1.listItems.count) == 2
                                    expect(listItemsSyncResult2.listItems.count) == 0
                                    
                                    let remoteListItem1 = listItemsSyncResult1.listItems[0]
                                    let remoteListItem2 = listItemsSyncResult1.listItems[1]
                                    
                                    TestUtils.testRemoteListItemMatches(remoteListItem1, updatedListItem1)
                                    TestUtils.testRemoteListItemMatches(remoteListItem2, listItem2)
                                    
                                    expect(listItemsSyncResult1.couldNotDelete).to(beEmpty())
                                    expect(listItemsSyncResult2.couldNotDelete).to(beEmpty())
                                    expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
                                    expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())


                                    // 4. Update (only) a list item - the server will update the lastUpdate timestamp from the list, matching the one from listitem (TODO server)
                                    let updatedAgainListItem2 = ListItem(uuid: listItem1.uuid, done: false, quantity: 2222, product: listItem1.product, section: listItem1.section, list: listItem1.list, order: listItem1.order, lastServerUpdate: remoteListItem2.lastUpdate)
                                    
                                    let listsSync = SyncUtils.toListsSync([], dbListItems: [updatedAgainListItem2])
                                    
                                    self?.remoteProvider.syncListsWithListItems(listsSync) {result in
                                        
                                        expect(result.success).to(beTrue())
                                        expect(result.successResult).toNot(beNil())
                                        
                                        if let syncResult = result.successResult {
                                            
                                            expect(syncResult.lists.count) == 2 // there are still 2 lists in the remote database
                                            expect(syncResult.couldNotDelete.count) == 0
                                            expect(syncResult.couldNotUpdate.count) == 0
                                            expect(syncResult.listItemsSyncResults.count) == 2 // still 2 listitems, for 2 lists
                                            
                                            let remoteList1 = syncResult.lists[0]
                                            let remoteList2 = syncResult.lists[1]
                                            
                                            TestUtils.testRemoteListMatches(remoteList1, updatedList1)
                                            TestUtils.testRemoteListMatches(remoteList2, list2)
                                            
                                            let listItemsSyncResult1 = syncResult.listItemsSyncResults[0]
                                            let listItemsSyncResult2 = syncResult.listItemsSyncResults[1]
                                            
                                            expect(listItemsSyncResult1.listUuid == list1.uuid)
                                            expect(listItemsSyncResult2.listUuid == list2.uuid)
                                            
                                            expect(listItemsSyncResult1.listItems.count) == 2
                                            expect(listItemsSyncResult2.listItems.count) == 0
                                            
                                            let remoteListItem1 = listItemsSyncResult1.listItems[0]
                                            let remoteListItem2 = listItemsSyncResult1.listItems[1]
                                            
                                            TestUtils.testRemoteListItemMatches(remoteListItem1, updatedListItem1)
                                            TestUtils.testRemoteListItemMatches(remoteListItem2, listItem2)
                                            
                                            expect(listItemsSyncResult1.couldNotDelete).to(beEmpty())
                                            expect(listItemsSyncResult2.couldNotDelete).to(beEmpty())
                                            expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
                                            expect(listItemsSyncResult2.couldNotUpdate).to(beEmpty())
                                            
                                            // TODO after server change, test lastUpdate list1 == lastUpdate remoteListItem2

                                            
                                            // 5. Delete list1 - the list items also have to be deleted
                                            let updatedOnceAgainList1 = List(uuid: list1.uuid, name: "mylist1-updated", lastServerUpdate: remoteList1.lastUpdate, removed: true)
                                            // Try to update listitem from list1 - here nothing will happen, since list is deleted (not expected to be in cannotUpdate)
                                            let updatedAgainListItem1 = ListItem(uuid: listItem1.uuid, done: false, quantity: 1111, product: listItem1.product, section: listItem1.section, list: listItem1.list, order: listItem1.order, lastServerUpdate: remoteListItem1.lastUpdate) // valid update (== timestamp in server)
                                            
                                            let listsSync = SyncUtils.toListsSync([updatedOnceAgainList1], dbListItems: [updatedAgainListItem1])
                                            
                                            self?.remoteProvider.syncListsWithListItems(listsSync) {result in
                                                
                                                expect(result.success).to(beTrue())
                                                expect(result.successResult).toNot(beNil())
                                                
                                                if let syncResult = result.successResult {
                                                    
                                                    expect(syncResult.lists.count) == 1 // list was deleted
                                                    expect(syncResult.couldNotDelete.count) == 0
                                                    expect(syncResult.couldNotUpdate.count) == 0
                                                    expect(syncResult.listItemsSyncResults.count) == 1 // only one list left - only group of listitems
                                                    
                                                    let remoteList1 = syncResult.lists[0]
                                                    
                                                    TestUtils.testRemoteListMatches(remoteList1, list2)
                                                    
                                                    let listItemsSyncResult1 = syncResult.listItemsSyncResults[0]
                                                    
                                                    expect(listItemsSyncResult1.listUuid == list2.uuid)
                                                    
                                                    expect(listItemsSyncResult1.listItems.count) == 0
                                                    
                                                    expect(listItemsSyncResult1.couldNotDelete).to(beEmpty())
                                                    expect(listItemsSyncResult1.couldNotUpdate).to(beEmpty())
                                                    
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
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
