//
//  BrandProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class BrandProviderImpl: BrandProvider {
    
    private let dbProvider = RealmBrandProvider()
    private let remoteProductProvider = RemoteProductProvider()
    
    func brandsContainingText(text: String, _ handler: ProviderResult<[String]> -> ()) {
        dbProvider.brandsContainingText(text) {brands in
            handler(ProviderResult(status: .Success, sucessResult: brands))
        }
    }
    
    func brands(range: NSRange, _ handler: ProviderResult<[String]> -> Void) {
        dbProvider.brands(range) {brands in
            handler(ProviderResult(status: .Success, sucessResult: brands))
        }
    }
    
    func updateBrand(oldName: String, newName: String, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.updateBrand(oldName, newName: newName) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Providers.listItemsProvider.invalidateMemCache()
                Providers.inventoryItemsProvider.invalidateMemCache()
            }
            handler(ProviderResult(status: success ? .Success : .Unknown))
            
            // TODO server - for now not important as the screen where we can do this will be disabled for coming release
        }
    }
    
    func removeProductsWithBrand(name: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.removeProductsWithBrand(name, markForSync: remote) {[weak self] success in
            if success {
                // Trigger to reload items from database to see updated brands
                Providers.listItemsProvider.invalidateMemCache()
                Providers.inventoryItemsProvider.invalidateMemCache()
            
                handler(ProviderResult(status: .Success))
                
                if remote {
                    self?.remoteProductProvider.deleteProductsWithBrand(name) {remoteResult in
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                QL4("Error removing products with brand from local db: \(name)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func brandsContainingText(text: String, range: NSRange, _ handler: ProviderResult<[String]> -> Void) {
        dbProvider.brandsContainingText(text, range: range) {brands in
            handler(ProviderResult(status: .Success, sucessResult: brands))
        }
    }
}
