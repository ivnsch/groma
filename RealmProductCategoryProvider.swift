//
//  RealmProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmProductCategoryProvider: RealmProvider {
    
    // TODO range
    func categories(_ range: NSRange, _ handler: @escaping (Results<ProductCategory>?) -> Void) {
        handler(loadSync(filter: nil))
    }
    
    func categoriesContainingText(_ text: String, _ handler: @escaping (Results<ProductCategory>?) -> Void) {
        load(filter: ProductCategory.createFilterNameContains(text), handler: handler)
    }
    
    // TODO range
    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (_ text: String?, _ categories: Results<ProductCategory>?) -> Void) {
        load(filter: ProductCategory.createFilterNameContains(text)) {categories in
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
                let realm = try Realm()
                try realm.write {
                    self?.removeCategorySync(realm, categoryUuid: categoryUuid, markForSync: markForSync)
                }
                return true
            } catch let error {
                QL4("Realm error: \(error)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    fileprivate func removeCategorySync(_ realm: Realm, categoryUuid: String, markForSync: Bool) {
        let dbProducts: Results<Product> = realm.objects(Product.self).filter(Product.createFilterCategory(categoryUuid))
        // delete first dependencies of products (realm requires this order, otherwise db is inconsistent. There's no cascade delete yet also).
        for dbProduct in dbProducts {
            _ = DBProviders.productProvider.deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync)
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
            guard let categories = categories else {QL4("No results"); handler(nil); return}
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
                QL2("No categories with name: \(categoryName) - nothing to remove") // this is not an error, this can be used e.g. in the autosuggestions where we list also section names.
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
        _ = DBProviders.productProvider.removeProductsForCategorySync(realm, categoryUuid: categoryUuid, markForSync: markForSync)
    }
}
