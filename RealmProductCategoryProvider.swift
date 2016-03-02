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
    
    func categories(range: NSRange, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, range: range, handler: handler)
    }
    
    func categoriesContainingText(text: String, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: DBProductCategory.createFilterNameContains(text), handler: handler)
    }
    
    func categoriesContainingText(text: String, range: NSRange, _ handler: (text: String?, categories: [ProductCategory]) -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: DBProductCategory.createFilterNameContains(text), range: range) {categories in
            handler(text: text, categories: categories)
        }
    }
    
    func updateCategory(category: ProductCategory, _ handler: Bool -> Void) {
        let dbCategory = ProductCategoryMapper.dbWithCategory(category)
        saveObj(dbCategory, update: true, handler: handler)
    }
    
    func removeCategory(category: ProductCategory, markForSync: Bool, _ handler: Bool -> Void) {
        background({[weak self] in
            do {
                let realm = try Realm()
                try realm.write {
                    let dbProducts: Results<DBProduct> = realm.objects(DBProduct).filter(DBProduct.createFilterCategory(category.uuid))
                    // delete first dependencies of products (realm requires this order, otherwise db is inconsistent. There's no cascade delete yet also).
                    for dbProduct in dbProducts {
                        RealmListItemProvider().deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync)
                    }
                    
                    // delete products
                    realm.delete(dbProducts)
                    if markForSync {
                        let toRemoveProducts = dbProducts.map{DBProductToRemove($0)}
                        self?.saveObjsSyncInt(realm, objs: toRemoveProducts, update: true)
                    }
                    
                    // delete cateogories
                    let dbCategories = realm.objects(DBProductCategory).filter(DBProductCategory.createFilter(category.uuid))
                    realm.delete(dbCategories)
                    if markForSync {
                        let toRemoveCategories = dbCategories.map{DBRemoveProductCategory($0)}
                        self?.saveObjsSyncInt(realm, objs: toRemoveCategories, update: true)
                    }
                    
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
    
    func updateLastSyncTimeStamp(category: RemoteProductCategory, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, category: category)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(realm: Realm, category: RemoteProductCategory) {
        realm.create(DBProductCategory.self, value: category.timestampUpdateDict, update: true)
    }
    
    func clearCategoryTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveProductCategory.self, DBRemoveProductCategory.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}
