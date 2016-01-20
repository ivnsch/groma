//
//  BrandProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class BrandProviderImpl: BrandProvider {
    
    private let dbProvider = RealmBrandProvider()
    
    func brands(handler: ProviderResult<[String]> -> ()) {
        dbProvider.brands {brands in
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
        }
    }
    
    func removeBrand(name: String, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.removeBrand(name) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Providers.listItemsProvider.invalidateMemCache()
                Providers.inventoryItemsProvider.invalidateMemCache()
            }
            handler(ProviderResult(status: success ? .Success : .Unknown))
        }
    }
    
    func brandsContainingText(text: String, _ handler: ProviderResult<[String]> -> Void) {
        dbProvider.brandsContainingText(text) {brands in
            handler(ProviderResult(status: .Success, sucessResult: brands))
        }
    }
}
