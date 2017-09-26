//
//  ProductCategoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

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
    
    func categoriesContainingText(_ text: String,  _ handler: @escaping (ProviderResult<Results<ProductCategory>>) -> Void) {
        dbCategoryProvider.categoriesContainingText(text) {categories in
            if let categories = categories {
                handler(ProviderResult(status: .success, sucessResult: categories))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<(text: String?, categories: Results<ProductCategory>)>) -> Void) {
        dbCategoryProvider.categoriesContainingText(text, range: range) {result in
            if let categories = result.1 {
                handler(ProviderResult(status: .success, sucessResult: (result.0, categories)))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }

    func categorySuggestions(_ handler: @escaping (ProviderResult<[Suggestion]>) -> ()) {
        dbProductProvider.loadCategorySuggestions {suggestions in
            handler(ProviderResult(status: .success, sucessResult: suggestions))
        }
    }
    
    func categories(_ range: NSRange, _ handler: @escaping (ProviderResult<Results<ProductCategory>>) -> Void) {
        dbCategoryProvider.categories(range) {categories in
            if let categories = categories {
                handler(ProviderResult(status: .success, sucessResult: categories))
            } else {
                handler(ProviderResult(status: .unknown))
            }
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
                            logger.e("Remote call no success: \(remoteResult)")
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
        DBProv.productCategoryProvider.removeCategory(categoryUuid, markForSync: true) {[weak self] success in
            handler(ProviderResult(status: success ? .success : .unknown))
            
            if remote {
                self?.remoteCategoryProvider.removeCategory(categoryUuid) {remoteResult in
                    if remoteResult.success {
                        self?.dbCategoryProvider.clearCategoryTombstone(categoryUuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                logger.e("Couldn't delete tombstone for product category: \(categoryUuid)")
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
        DBProv.productCategoryProvider.removeAllWithName(categoryName, markForSync: true) {removedCategoriesMaybe in
            if let _ = removedCategoriesMaybe {
                handler(ProviderResult(status: .success))

                // for now remote disabled
//                if remote {
//                    self?.remoteCategoryProvider.removeCategoriesWithName(categoryName) {remoteResult in
//                        if remoteResult.success {
//                            
//                            let removedCategoriesUuids = removedCategories.map{$0.uuid}
//                            DBProv.productCategoryProvider.clearCategoriesTombstones(removedCategoriesUuids) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    logger.e("Couldn't delete tombstones for categories: \(removedCategories)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
            } else {
                logger.e("Couldn't remove sections from db for name: \(categoryName)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}
