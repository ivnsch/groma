//
//  ProductCategoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class ProductCategoryProviderImpl: ProductCategoryProvider {

    fileprivate let dbProductProvider = RealmProductProvider()
    fileprivate let dbCategoryProvider = RealmProductCategoryProvider()
    fileprivate let remoteCategoryProvider = RemoteProductCategoryProvider()

    func categoryWithName(_ name: String, _ handler: @escaping (ProviderResult<ProductCategory>) -> Void) {
        dbProductProvider.categoryWithName(name) {categoryMaybe in
            if let category = categoryMaybe {
                handler(ProviderResult(status: .success, sucessResult: category))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }
    
    func categoryWithNameOpt(_ name: String, _ handler: @escaping (ProviderResult<ProductCategory?>) -> Void) {
        dbProductProvider.categoryWithName(name) {categoryMaybe in
            handler(ProviderResult(status: .success, sucessResult: categoryMaybe))
        }
    }
    
    func categoriesContainingText(_ text: String,  _ handler: @escaping (ProviderResult<[ProductCategory]>) -> Void) {
        dbCategoryProvider.categoriesContainingText(text) {categories in
            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: categories))
        }
    }
    
    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<(text: String?, categories: [ProductCategory])>) -> Void) {
        dbCategoryProvider.categoriesContainingText(text, range: range) {categories in
            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: categories))
        }
    }

    func categorySuggestions(_ handler: @escaping (ProviderResult<[Suggestion]>) -> ()) {
        dbProductProvider.loadCategorySuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: dbSuggestions))
        }
    }
    
    func categories(_ range: NSRange, _ handler: @escaping (ProviderResult<[ProductCategory]>) -> Void) {
        dbCategoryProvider.categories(range) {categories in
            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: categories))
            // For categories no background sync, not justified as this screen is not used frequently, also when there are new categories it's always because new list/inventory/group items were added, and we get these new categories already as a dependency in the respective background updates of these items (+ we have websocket - background sync is a "just in case" operation)
        }
    }
    
    func update(_ category: ProductCategory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbCategoryProvider.updateCategory(category) {[weak self] success in
           handler(ProviderResult(status: success ? .success : .unknown))
            
            if remote {
                self?.remoteCategoryProvider.updateCategory(category) {remoteResult in
                    if let remoteCategory = remoteResult.successResult {
                        self?.dbCategoryProvider.updateLastSyncTimeStamp(remoteCategory) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<ProductCategory>) in
                            QL4("Remote call no success: \(remoteResult)")
                        })
                    }
                }
            }
        }
    }
    
    func remove(_ category: ProductCategory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remove(category.uuid, remote: remote, handler)
    }
    
    func remove(_ categoryUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProviders.productCategoryProvider.removeCategory(categoryUuid, markForSync: true) {[weak self] success in
            handler(ProviderResult(status: success ? .success : .unknown))
            
            if remote {
                self?.remoteCategoryProvider.removeCategory(categoryUuid) {remoteResult in
                    if remoteResult.success {
                        self?.dbCategoryProvider.clearCategoryTombstone(categoryUuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for product category: \(categoryUuid)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, errorMsg: "removeGroupItem\(categoryUuid)", handler: handler)
                    }
                }
            }
        }
    }
    
    func removeAllCategoriesWithName(_ categoryName: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProviders.productCategoryProvider.removeAllWithName(categoryName, markForSync: true) {[weak self] removedCategoriesMaybe in
            if let removedCategories = removedCategoriesMaybe {
                handler(ProviderResult(status: .success))
                
                if remote {
                    self?.remoteCategoryProvider.removeCategoriesWithName(categoryName) {remoteResult in
                        if remoteResult.success {
                            
                            let removedCategoriesUuids = removedCategories.map{$0.uuid}
                            DBProviders.productCategoryProvider.clearCategoriesTombstones(removedCategoriesUuids) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstones for categories: \(removedCategories)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Couldn't remove sections from db for name: \(categoryName)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}
