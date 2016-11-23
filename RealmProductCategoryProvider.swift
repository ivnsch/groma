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
    
    func categories(_ range: NSRange, _ handler: @escaping ([ProductCategory]) -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, range: range, handler: handler)
    }
    
    func categoriesContainingText(_ text: String, _ handler: @escaping ([ProductCategory]) -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: DBProductCategory.createFilterNameContains(text), handler: handler)
    }
    
    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (_ text: String?, _ categories: [ProductCategory]) -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: DBProductCategory.createFilterNameContains(text), range: range) {categories in
            handler(text, categories)
        }
    }
    
    func categoriesWithName(_ name: String, handler: @escaping ([ProductCategory]) -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        self.load(mapper, filter: DBProductCategory.createFilterName(name), handler: handler)
    }
    
    func updateCategory(_ category: ProductCategory, _ handler: @escaping (Bool) -> Void) {
        let dbCategory = ProductCategoryMapper.dbWithCategory(category)
        saveObj(dbCategory, update: true, handler: handler)
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
        let dbProducts: Results<DBProduct> = realm.objects(DBProduct.self).filter(DBProduct.createFilterCategory(categoryUuid))
        // delete first dependencies of products (realm requires this order, otherwise db is inconsistent. There's no cascade delete yet also).
        for dbProduct in dbProducts {
            _ = DBProviders.productProvider.deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync)
        }
        
        // delete products
        realm.delete(dbProducts)
        if markForSync {
            let toRemoveProducts = Array(dbProducts.map{DBProductToRemove($0)})
            saveObjsSyncInt(realm, objs: toRemoveProducts, update: true)
        }
        
        // delete cateogories
        let dbCategories = realm.objects(DBProductCategory.self).filter(DBProductCategory.createFilter(categoryUuid))
        realm.delete(dbCategories)
        if markForSync {
            let toRemoveCategories = Array(dbCategories.map{DBRemoveProductCategory($0)})
            saveObjsSyncInt(realm, objs: toRemoveCategories, update: true)
        }
    }
    
    func removeAllWithName(_ categoryName: String, markForSync: Bool, handler: @escaping ([ProductCategory]?) -> Void) {
        categoriesWithName(categoryName) {[weak self] categories in guard let weakSelf = self else {return}
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
                handler([])
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
        realm.create(DBProductCategory.self, value: category.timestampUpdateDict, update: true)
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
