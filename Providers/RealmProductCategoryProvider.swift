//
//  RealmProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class RealmProductCategoryProvider: RealmProvider {
    
    // TODO range
    func categories(_ range: NSRange, _ handler: @escaping (Results<ProductCategory>?) -> Void) {
        handler(loadSync(filter: nil))
    }
    
    func categoriesContainingText(_ text: String, _ handler: @escaping (Results<ProductCategory>?) -> Void) {
        background({() -> [String]? in
            do {
                let realm = try RealmConfig.realm()
                let filterMaybe: String? = text.isEmpty ? nil : ProductCategory.createFilterNameContains(text)
                let result: Results<ProductCategory> = self.loadSync(realm, filter: filterMaybe)
                return result.map{$0.uuid}
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {uuidsMaybe in
            do {
                if let uuids = uuidsMaybe {
                    let realm = try RealmConfig.realm()
                    handler(self.loadSync(realm, filter: ProductCategory.createFilterUuids(uuids)))
                
                } else {
                    logger.v("No categories with text: \(text)")
                    handler(nil)
                }
                
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }
    
    // TODO range
    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (_ text: String?,
        _ categories: Results<ProductCategory>?) -> Void) {
        let filterMaybe: String? = text.isEmpty ? nil : ProductCategory.createFilterNameContains(text)
        load(filter: filterMaybe) {categories in
            handler(text, categories)
        }
    }
    
    func categoriesWithName(_ name: String, handler: @escaping (Results<ProductCategory>?) -> Void) {
        self.load(filter: ProductCategory.createFilterName(name), handler: handler)
    }
    
    func updateCategory(_ category: ProductCategory, _ handler: @escaping (Bool) -> Void) {
        saveObj(category, update: true, handler: handler)
    }
    
    func removeCategory(_ category: ProductCategory, markForSync: Bool, _ handler: @escaping (Bool) -> Void) {
        removeCategory(category.uuid, markForSync: markForSync, handler)
    }
    
    func removeCategory(_ categoryUuid: String, markForSync: Bool, _ handler: @escaping (Bool) -> Void) {
        background({[weak self] in
            do {
                let realm = try RealmConfig.realm()
                try realm.write {
                    self?.removeCategorySync(realm, categoryUuid: categoryUuid, markForSync: markForSync)
                }
                return true
            } catch let error {
                logger.e("Realm error: \(error)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    func category(name: String, handler: @escaping (ProductCategory?) -> Void) {
        
        categoriesWithName(name) {categoriesResult in
            if let categoriesResult = categoriesResult {
                if let category = categoriesResult.first {
                    handler(category)
                    
                } else {
                    logger.e("Couldn't load categories")
                    handler(nil)
                }
                
            } else { // category doesn't exist
                handler(nil)
            }
        }
    }
    
    func updateOrCreateCategory(name: String, color: UIColor, handler: @escaping (ProductCategory?) -> Void) {
        
        func onHasNewOrUpdatedCategory(category: ProductCategory) {
            doInWriteTransactionSync {realm in
                realm.add(category, update: true)
                handler(category)
            }
        }
        
        category(name: name) {categoryMaybe in
            if let category = categoryMaybe {
                onHasNewOrUpdatedCategory(category: category.copy(color: color))
                
            } else {
                logger.v("Category doesn't exists: \(name)")
                let newCategory = ProductCategory(uuid: UUID().uuidString, name: name, color: color.hexStr)
                onHasNewOrUpdatedCategory(category: newCategory)
            }
        }
    }
    
    fileprivate func removeCategorySync(_ realm: Realm, categoryUuid: String, markForSync: Bool) {
        let dbProducts: Results<Product> = realm.objects(Product.self).filter(Product.createFilterCategory(categoryUuid))
        // delete first dependencies of products (realm requires this order, otherwise db is inconsistent. There's no cascade delete yet also).
        for dbProduct in dbProducts {
            _ = DBProv.productProvider.deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync)
        }
        
        // delete products
        realm.delete(dbProducts)
        if markForSync {
            let toRemoveProducts = Array(dbProducts.map{ProductToRemove($0)})
            saveObjsSyncInt(realm, objs: toRemoveProducts, update: true)
        }
        
        // delete cateogories
        let dbCategories = realm.objects(ProductCategory.self).filter(ProductCategory.createFilter(categoryUuid))
        realm.delete(dbCategories)
        if markForSync {
            let toRemoveCategories = Array(dbCategories.map{DBRemoveProductCategory($0)})
            saveObjsSyncInt(realm, objs: toRemoveCategories, update: true)
        }
    }
    
    func removeAllWithName(_ categoryName: String, markForSync: Bool, handler: @escaping (Results<ProductCategory>?) -> Void) {
        categoriesWithName(categoryName) {[weak self] categories in guard let weakSelf = self else {return}
            guard let categories = categories else {logger.e("No results"); handler(nil); return}
            if !categories.isEmpty {
                weakSelf.doInWriteTransaction({realm in
                    for category in categories {
                        self?.removeCategorySync(realm, categoryUuid: category.uuid, markForSync: markForSync)
                    }
                    return categories
                    }, finishHandler: {removedSectionsMaybe in
                        handler(removedSectionsMaybe)
                })
                
            } else {
                logger.d("No categories with name: \(categoryName) - nothing to remove") // this is not an error, this can be used e.g. in the autosuggestions where we list also section names.
                handler(nil)
            }
        }
    }
    
    // MARK: - Sync
    
    func updateLastSyncTimeStamp(_ category: RemoteProductCategory, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, category: category)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(_ realm: Realm, category: RemoteProductCategory) {
        realm.create(ProductCategory.self, value: category.timestampUpdateDict, update: true)
    }
    
    func clearCategoryTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.clearCategoryTombstoneSync(realm, uuid: uuid)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearCategoriesTombstones(_ uuids: [String], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            for uuid in uuids {
                self?.clearCategoryTombstoneSync(realm, uuid: uuid)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    fileprivate func clearCategoryTombstoneSync(_ realm: Realm, uuid: String) {
        realm.deleteForFilter(DBRemoveProductCategory.self, DBRemoveProductCategory.createFilter(uuid))
    }
    
    func removeCategoryDependenciesSync(_ realm: Realm, categoryUuid: String, markForSync: Bool) {
        _ = DBProv.productProvider.removeProductsForCategorySync(realm, categoryUuid: categoryUuid, markForSync: markForSync)
    }
    
    
    // MARK: - Sync
    
    func loadCategoryWithUniqueSync(_ name: String) -> ProvResult<ProductCategory?, DatabaseError> {
        return withRealmSync {realm in
            let categoryMaybe: ProductCategory? = self.loadSync(realm, filter: ProductCategory.createFilterName(name)).first
            return .ok(categoryMaybe)
        }!
    }
    
    // TODO remove - use the other mergeOrCreateCategorySync
    func mergeOrCreateCategorySync(name: String, color: UIColor, save: Bool) -> ProvResult<ProductCategory, DatabaseError> {
        
        let result: ProvResult<ProductCategory, DatabaseError> = loadCategoryWithUniqueSync(name).map ({
            if let existingCategory = $0 {
                return existingCategory.copy(name: name, color: color)
            } else {
                return ProductCategory(uuid: UUID().uuidString, name: name, color: color)
            }
        })
        
        return !save ? result : result.flatMap {category in
            let writeSuccess: Bool? = self.doInWriteTransactionSync({realm in
                realm.add(category, update: true)
                return true
            })
            return (writeSuccess ?? false) ? .ok(category) : .err(.unknown)
        }
    }
    
    
    // TODO!!!!!!!!!!!!!!! orient maybe with similar method in product for transaction etc. Product also needs refactoring though
    func mergeOrCreateCategorySync(categoryInput: CategoryInput, doTransaction: Bool, notificationToken: NotificationToken?) -> ProvResult<ProductCategory, DatabaseError> {
        
        func transactionContent() -> ProvResult<ProductCategory, DatabaseError> {
            
            return DBProv.productCategoryProvider.loadCategoryWithUniqueSync(categoryInput.name).map {existingCategoryMaybe in
                if let existingCategory = existingCategoryMaybe {
                    existingCategory.color = categoryInput.color
                    return existingCategory
                    
                } else {
                    let newCategory = ProductCategory(uuid: UUID().uuidString, name: categoryInput.name, color: categoryInput.color)
                    //                    if save {
                    //                        realm.add(newCategory, update: true)
                    //                    }
                    return newCategory
                }
            }
        }
        
        if doTransaction {
            return doInWriteTransactionSync(withoutNotifying: notificationToken.map{[$0]} ?? [], realm: nil) {realm in
                return transactionContent()
                } ?? .err(.unknown)
        } else {
            return transactionContent()
        }
    }
    
}
