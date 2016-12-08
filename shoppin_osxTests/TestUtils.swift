//
//  TestUtils.swift
//  shoppin
//
//  Created by ischuetz on 20/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Nimble
import Alamofire
import Valet

class TestUtils {

    static let userInput1 = UserInput(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
    static let userInput2 = UserInput(email: "test@test.test", password: "test123", firstName: "test", lastName: "tester")
    
    static let listInput1 = List(uuid: NSUUID().UUIDString, name: "my-first-list", users: [SharedUser(email: "foo@bar.com")])
    static let listInput2 = List(uuid: NSUUID().UUIDString, name: "my-second-list", users: [SharedUser(email: "test@test.test")])
    
    static let remoteUserProvider = RemoteUserProvider()
    static let remoteListItemProvider = RemoteListItemProvider()

    
    class func withClearedDatabase(f: () -> ()) {
        
        Alamofire.request(.GET, URLString: Urls.removeAll).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            expect(remoteResult.status) == RemoteStatusCode.Success
            f()
        }
    }
    
    class func withClearDatabaseAndNewLoggedInAccountUser1AndAddedList1(onComplete: (LoginData, RemoteList) -> ()) {
        self.withClearDatabaseAndNewLoggedInAccount(user: self.userInput1, onLoggedIn: {loginData in
            
            self.remoteListItemProvider.add(self.listInput1, handler: {addListResult in
                
                expect(addListResult.success).to(beTrue())
                expect(addListResult.successResult).toNot(beNil())
                
                onComplete(loginData, addListResult.successResult!)
            })
        })
    }
    
    
    // TODO needs better helpers for muti-user (store different tokens)
    // helper for multiuser tests
    class func withClearDatabaseAndNewLoggedInAccountUser1(onLoggedIn: (LoginData) -> ()) {
        self.withClearDatabaseAndNewLoggedInAccount(user: self.userInput1, onLoggedIn: onLoggedIn)
    }

    // helper for multiuser tests
    class func withClearDatabaseAndNewLoggedInAccountUser2(onLoggedIn: (LoginData) -> ()) {
        self.withClearDatabaseAndNewLoggedInAccount(user: self.userInput2, onLoggedIn: onLoggedIn)
    }
    
    // helper for multiuser tests
    class func withNewLoggedInAccountUser1(onLoggedIn: (LoginData) -> ()) {
        self.withNewLoggedInAccount(user: TestUtils.userInput1, onLoggedIn: onLoggedIn)
    }
    
    // helper for multiuser tests
    class func withNewLoggedInAccountUser2(onLoggedIn: (LoginData) -> ()) {
        self.withNewLoggedInAccount(user: TestUtils.userInput2, onLoggedIn: onLoggedIn)
    }
    
    class func withClearDatabaseAndNewLoggedInAccount(user user: UserInput = TestUtils.userInput1, onLoggedIn: (LoginData) -> ()) {
        // ensure empty keychain
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeAllObjects()
        
        TestUtils.withClearedDatabase {
            self.withNewLoggedInAccount(user: user, onLoggedIn: onLoggedIn)
        }
    }

    class func testNotAuthenticated<T>(result: RemoteResult<T>) {
        expect(result.status) == RemoteStatusCode.NotAuthenticated
    }
    //a failed attempt to merge withClearedDatabase and testNotAuthenticated to write less code. The idea is to have 1-2 liners to check if services are protected
//    class func testUnauthenticatedAccess<T>(remoteCall: (handler: RemoteResult<[RemoteList]> -> ()) -> ()) {
//
//        TestUtils.withClearedDatabase {
//            remoteCall {result in
//                expect(result.status) == RemoteStatusCode.NotAuthenticated
//            }
//        }
//    }
    

    class func withNewLoggedInAccount(user user: UserInput = TestUtils.userInput1, onLoggedIn: (LoginData) -> ()) {
        
        // ensure empty keychain
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeAllObjects()
        
        let user = UserInput(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
        
        self.remoteUserProvider.register(user, handler: {result in
            
            expect(result.success).to(beTrue())
            expect(result.successResult).toNot(beNil())
            
            let loginData = LoginData(email: user.email, password: user.password)
            onLoggedIn(loginData)

//            let loginData = LoginData(email: user.email, password: user.password)
//            
//            self.remoteUserProvider.login(loginData, handler: {result in
//                
//                expect(result.success).to(beTrue())
//                expect(result.successResult).toNot(beNil())
//                
//                onLoggedIn(loginData)
//            })
        })
    }
    
    
    class func withNewLoggedInAccount(onLoggedIn: (LoginData) -> ()) {
        
        // ensure empty keychain
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeAllObjects()
        
        let user = UserInput(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
        
        self.remoteUserProvider.register(user, handler: {result in
            
            expect(result.success).to(beTrue())
            expect(result.successResult).to(beNil())
            
            let loginData = LoginData(email: user.email, password: user.password)
            
            self.remoteUserProvider.login(loginData, handler: {result in
                
                expect(result.success).to(beTrue())
                expect(result.successResult).toNot(beNil())
                
                onLoggedIn(loginData)
            })
        })
    }
    
    class func testIfSuccessWithResult<T>(result: RemoteResult<T>) {
        TestUtils.ifSuccessMustBeResultNotNil(result)
        TestUtils.ifResultNotNilMustBeSuccess(result)
    }
    
    class func ifSuccessMustBeResultNotNil<T>(result: RemoteResult<T>) {
        if result.success {
            expect(result.successResult).notTo(beNil())
        }
    }

    // This should be always the case - all tests should make this check
    class func ifResultNotNilMustBeSuccess<T>(result: RemoteResult<T>) {
        if result.successResult != nil {
            expect(result.success).to(beTrue())
        }
    }
    
    class func testRemoteListValid(remoteList: RemoteList) {
        expect(remoteList.uuid).notTo(beEmpty())
        expect(remoteList.name).notTo(beEmpty())
        expect(remoteList.users).notTo(beEmpty())
    }
    
    // TODO remove this, we should need only testRemoteListWithSharedUsersMatches
    class func testRemoteListMatches(remoteList: RemoteList, _ list: List) {
        expect(remoteList.uuid) == list.uuid
        expect(remoteList.name) == list.name
//        expect(remoteList.users.count) == list.users.count
    }

    class func testRemoteInventoryMatches(remoteInventory: RemoteInventory, _ inventory: Inventory) {
        expect(remoteInventory.uuid) == inventory.uuid
        expect(remoteInventory.name) == inventory.name
    }
    
    class func testRemoteListWithSharedUsersMatches(remoteList: RemoteList, _ list: List) {
        expect(remoteList.uuid) == list.uuid
        expect(remoteList.name) == list.name
        expect(remoteList.users.count) == list.users.count
        
        for i in 0..<remoteList.users.count {
            self.testRemoteSharedUserMatchesWithInput(remoteList.users[i], list.users[i])
        }
    }
    
    class func testRemoteSharedUserMatchesWithInput(remoteSharedUser: RemoteSharedUser, _ sharedUserInput: DBSharedUser) {
        expect(remoteSharedUser.email) == sharedUserInput.email
    }

    class func testRemoteSectionValid(remoteSection: RemoteSection) {
        expect(remoteSection.uuid).notTo(beEmpty())
        expect(remoteSection.name).notTo(beEmpty())
    }
    
    class func testRemoteSectionMatches(remoteSection: RemoteSection, _ section: Section) {
        expect(remoteSection.uuid) == section.uuid
        expect(remoteSection.name) == section.name
    }

    class func testRemoteProductValid(remoteProduct: RemoteProduct) {
        expect(remoteProduct.uuid).notTo(beEmpty())
        expect(remoteProduct.name).notTo(beEmpty())
        expect(remoteProduct.price).notTo(beLessThan(0))
    }
    
    class func testRemoteProductMatches(remoteProduct: RemoteProduct, _ product: Product) {
        expect(remoteProduct.uuid) == product.uuid
        expect(remoteProduct.name) == product.name
        expect(remoteProduct.price) == product.price
    }

    class func testRemoteInventoryItemMatches(remoteInventoryItem: RemoteInventoryItemWithProduct, _ inventoryItem: InventoryItem) {
        expect(remoteInventoryItem.inventoryItem.quantity) == (inventoryItem.quantity + inventoryItem.quantityDelta)
        self.testRemoteProductMatches(remoteInventoryItem.product, inventoryItem.product)
    }

    class func testRemoteListItemValid(remoteListItem: RemoteListItem) {
        expect(remoteListItem.uuid).notTo(beEmpty())
        expect(remoteListItem.productUuid).notTo(beEmpty())
        expect(remoteListItem.sectionUuid).notTo(beEmpty())
        expect(remoteListItem.listUuid).notTo(beEmpty())
        expect(remoteListItem.order).notTo(beLessThan(0))
        expect(remoteListItem.quantity).notTo(beLessThan(0))
    }
    
    class func testHistoryItemMatches(remoteHistoryItem: RemoteHistoryItem, inventoryItemWithHistory: InventoryItemWithHistoryEntry, remoteHistoryItems: RemoteHistoryItems) {
        expect(remoteHistoryItem.uuid) == inventoryItemWithHistory.historyItemUuid
        expect(remoteHistoryItem.inventoryUuid) == inventoryItemWithHistory.inventoryItem.inventory.uuid
        expect(remoteHistoryItem.productUuid) == inventoryItemWithHistory.inventoryItem.product.uuid
        expect(remoteHistoryItem.quantity) == inventoryItemWithHistory.inventoryItem.quantityDelta // Note that this is used for add service, not sync - when adding the service is called immediately and quantityDelta is only the quantity for the current item (when incrementing inventory items in the local database offline/without account delta is an accumulation since the last sync).

        let remoteInventory = remoteHistoryItems.inventories.findFirst {$0.uuid == remoteHistoryItem.inventoryUuid}
        expect(remoteInventory).notTo(beNil())
        self.testRemoteInventoryMatches(remoteInventory!, inventoryItemWithHistory.inventoryItem.inventory)
        
        let remoteProduct = remoteHistoryItems.products.findFirst {$0.uuid == remoteHistoryItem.productUuid}
        expect(remoteProduct).notTo(beNil())
        self.testRemoteProductMatches(remoteProduct!, inventoryItemWithHistory.inventoryItem.product)
        
        let remoteUser = remoteHistoryItems.users.findFirst {$0.uuid == remoteHistoryItem.userUuid}
        expect(remoteUser).notTo(beNil())
        expect(remoteUser!.email) == inventoryItemWithHistory.user.email
        
        // TODO fix (all) dates, this doesn't work, server saves 1970, etc. Work with UTC.
        // Here the server receives the same long we send. But sends back a slightly different one. Probably issue happens when save and load from db
//        expect(remoteHistoryItem.addedDate) == inventoryItemWithHistory.addedDate
    }
    
    class func testHistoryItemMatches(remoteHistoryItem: RemoteHistoryItem, historyItem: HistoryItem) {
        expect(remoteHistoryItem.uuid) == historyItem.uuid
        expect(remoteHistoryItem.productUuid) == historyItem.product.uuid
        expect(remoteHistoryItem.quantity) == historyItem.quantity
        expect(remoteHistoryItem.inventoryUuid) == historyItem.inventory.uuid
//        expect(remoteHistoryItem.addedDate) == historyItem.addedDate
    }
    
    class func testRemoteListItemMatches(remoteListItem: RemoteListItem, _ listItem: ListItem) {
        expect(remoteListItem.uuid) == listItem.uuid
        expect(remoteListItem.done) == listItem.done
        expect(remoteListItem.productUuid) == listItem.product.uuid
        expect(remoteListItem.sectionUuid) == listItem.section.uuid
        expect(remoteListItem.listUuid) == listItem.list.uuid
        expect(remoteListItem.order) == listItem.order
        expect(remoteListItem.quantity) == listItem.quantity
    }
    
    class func testRemoteListItemsValid(remoteListItems: RemoteListItems) {
        
        for p in remoteListItems.products {
            self.testRemoteProductValid(p)
        }
        for s in remoteListItems.sections {
            self.testRemoteSectionValid(s)
        }
        for l in remoteListItems.listItems {
            self.testRemoteListItemValid(l)
        }
    }
}
