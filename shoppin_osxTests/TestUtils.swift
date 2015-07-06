//
//  TestUtils.swift
//  shoppin
//
//  Created by ischuetz on 20/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Nimble
import Alamofire

class TestUtils {

    static let remoteUserProvider = RemoteUserProvider()

    class func withClearedDatabase(f: () -> ()) {
        
        Alamofire.request(.GET, Urls.removeAll).responseMyObject { (request, _, remoteResult: RemoteResult<NoOpSerializable>, error) in
            expect(remoteResult.status) == RemoteStatusCode.Success
            f()
        }
    }
    
    
    class func withClearDatabaseAndNewLoggedInAccount(onLoggedIn: (LoginData) -> ()) {
        // ensure empty keychain
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeAllObjects()
        
        TestUtils.withClearedDatabase {
            self.withNewLoggedInAccount(onLoggedIn)
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
    
    
    class func withNewLoggedInAccount(onLoggedIn: (LoginData) -> ()) {
        
        // ensure empty keychain
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeAllObjects()
        
        let user = User(email: "foo@bar.com", password: "password123", firstName: "ivan", lastName: "schuetz")
        
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
    }
    
    class func testRemoteListMatches(remoteList: RemoteList, _ list: List) {
        expect(remoteList.uuid) == list.uuid
        expect(remoteList.name) == list.name
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
    
    class func testRemoteListItemWithDataValid(remoteListItemWithData: RemoteListItemWithData) {
        self.testRemoteListItemValid(remoteListItemWithData.listItem)
        self.testRemoteProductValid(remoteListItemWithData.product)
        self.testRemoteListValid(remoteListItemWithData.list)
        self.testRemoteSectionValid(remoteListItemWithData.section)
    }
    
    class func testRemoteListItemWithDataMatches(remoteListItemWithData: RemoteListItemWithData, _ listItem: ListItem) {
        self.testRemoteListItemMatches(remoteListItemWithData.listItem, listItem)
        self.testRemoteSectionMatches(remoteListItemWithData.section, listItem.section)
        self.testRemoteListMatches(remoteListItemWithData.list, listItem.list)
        self.testRemoteProductMatches(remoteListItemWithData.product, listItem.product)
    }

    class func testRemoteListItemValid(remoteListItem: RemoteListItem) {
        expect(remoteListItem.uuid).notTo(beEmpty())
        expect(remoteListItem.productUuid).notTo(beEmpty())
        expect(remoteListItem.sectionUuid).notTo(beEmpty())
        expect(remoteListItem.listUuid).notTo(beEmpty())
        expect(remoteListItem.order).notTo(beLessThan(0))
        expect(remoteListItem.quantity).notTo(beLessThan(0))
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
        for l in remoteListItems.lists {
            self.testRemoteListValid(l)
        }
        for l in remoteListItems.listItems {
            self.testRemoteListItemValid(l)
        }
    }
}
