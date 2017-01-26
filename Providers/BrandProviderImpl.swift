//
//  BrandProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs
import RealmSwift

class BrandProviderImpl: BrandProvider {

    fileprivate let dbProvider = RealmBrandProvider()
    fileprivate let remoteProductProvider = RemoteProductProvider()
    
    func brandsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> ()) {
        dbProvider.brandsContainingText(text) {brands in
            handler(ProviderResult(status: .success, sucessResult: brands))
        }
    }
    
    func brands(_ range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        dbProvider.brands(range) {brands in
            handler(ProviderResult(status: .success, sucessResult: brands))
        }
    }
    
    func brands(productName: String, handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProv.brandProvider.brands(productName: productName) {brandsMaybe in
            if let brands = brandsMaybe {
                handler(ProviderResult(status: .success, sucessResult: brands))
            } else {
                QL4("Couldn't load brands")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func updateBrand(_ oldName: String, newName: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.updateBrand(oldName, newName: newName) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Prov.listItemsProvider.invalidateMemCache()
                Prov.inventoryItemsProvider.invalidateMemCache()
            }
            handler(ProviderResult(status: success ? .success : .unknown))
            
            // TODO server - for now not important as the screen where we can do this will be disabled for coming release
        }
    }
    
    func removeProductsWithBrand(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.removeProductsWithBrand(name, markForSync: remote) {[weak self] success in
            if success {
                // Trigger to reload items from database to see updated brands
                Prov.listItemsProvider.invalidateMemCache()
                Prov.inventoryItemsProvider.invalidateMemCache()
            
                handler(ProviderResult(status: .success))
                
                if remote {
                    self?.remoteProductProvider.deleteProductsWithBrand(name) {remoteResult in
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                QL4("Error removing products with brand from local db: \(name)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func brandsContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        dbProvider.brandsContainingText(text, range: range) {brands in
            handler(ProviderResult(status: .success, sucessResult: brands))
        }
    }
 
    func brands(ingredients: Results<Ingredient>, handler: @escaping (ProviderResult<[String: [String]]>) -> Void) {
        DBProv.brandProvider.brands(ingredients: ingredients) {dictMaybe in
            if let dict = dictMaybe {
                handler(ProviderResult(status: .success, sucessResult: dict))
            } else {
                QL4("Couldn't load brands")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}
