//
//  RealmStoreProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmStoreProductProvider: RealmProvider {
      
    func storeProduct(_ uuid: String, handler: @escaping (StoreProduct?) -> Void) {
        let mapper = {StoreProductMapper.productWithDB($0)}
        loadFirst(mapper, filter: DBStoreProduct.createFilter(uuid), handler: handler)
    }
    
    func storeProductSync(_ realm: Realm, uuid: String) -> StoreProduct? {
        let mapper = {StoreProductMapper.productWithDB($0)}
        return loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilter(uuid)).first
    }

    func storeProduct(_ product: Product, store: String, handler: @escaping (StoreProduct?) -> Void) {
        let mapper = {StoreProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store), handler: handler)
    }
    
    func storeProductSync(_ realm: Realm, product: Product, store: String) -> StoreProduct? {
        let mapper = {StoreProductMapper.productWithDB($0)}
        return loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store)).first
    }
    
    func storeProductSync(_ product: Product, store: String) -> StoreProduct? {
       return withRealmSync {[weak self] realm in
            let mapper = {StoreProductMapper.productWithDB($0)}
            return self?.loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store)).first
        }
    }
    
    func storeProductsSync(_ products: [Product], store: String) -> [StoreProduct]? {
        return withRealmSync {[weak self] realm in
            let mapper = {StoreProductMapper.productWithDB($0)}
            return self?.loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductsStores(products, store: store))
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteStoreProductDependenciesSync(_ realm: Realm, storeProductUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(DBStoreProduct.self).filter(DBStoreProduct.createFilter(storeProductUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }

    func deleteStoreProductsAndDependenciesForProductSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(DBStoreProduct.self).filter(DBStoreProduct.createFilterProduct(productUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }
    
    func deleteStoreProductsAndDependenciesSync(_ realm: Realm, storeProducts: Results<DBStoreProduct>, markForSync: Bool) -> Bool {
        let uuids = Array(storeProducts.map{$0.uuid})
        let listItemResult = realm.objects(DBListItem.self).filter(DBListItem.createFilterWithProducts(uuids))
        if markForSync {
            let toRemoveListItems = Array(listItemResult.map{DBRemoveListItem($0)})
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        realm.delete(listItemResult)
        
        if markForSync {
            let toRemoveStoreProducts = Array(storeProducts.map{DBStoreProductToRemove($0)})
            saveObjsSyncInt(realm, objs: toRemoveStoreProducts, update: true)
        }
        realm.delete(storeProducts)
        
        return true
    }
}
