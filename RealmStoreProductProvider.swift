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
    
    func storeProduct(uuid: String, handler: StoreProduct? -> Void) {
        let mapper = {StoreProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBStoreProduct.createFilter(uuid), handler: handler)
    }
    
    func storeProductSync(realm: Realm, uuid: String) -> StoreProduct? {
        let mapper = {StoreProductMapper.productWithDB($0)}
        return loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilter(uuid)).first
    }

    func storeProduct(product: Product, store: String, handler: StoreProduct? -> Void) {
        let mapper = {StoreProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store), handler: handler)
    }
    
    func storeProductSync(realm: Realm, product: Product, store: String) -> StoreProduct? {
        let mapper = {StoreProductMapper.productWithDB($0)}
        return loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store)).first
    }
    
    func storeProductSync(product: Product, store: String) -> StoreProduct? {
       return withRealmSync {[weak self] realm in
            let mapper = {StoreProductMapper.productWithDB($0)}
            return self?.loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductStore(product.uuid, store: store)).first
        }
    }
    
    func storeProductsSync(products: [Product], store: String) -> [StoreProduct]? {
        return withRealmSync {[weak self] realm in
            let mapper = {StoreProductMapper.productWithDB($0)}
            return self?.loadSync(realm, mapper: mapper, filter: DBStoreProduct.createFilterProductsStores(products, store: store))
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteStoreProductDependenciesSync(realm: Realm, storeProductUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(DBStoreProduct).filter(DBStoreProduct.createFilter(storeProductUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }

    func deleteStoreProductsAndDependenciesForProductSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(DBStoreProduct).filter(DBStoreProduct.createFilterProduct(productUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }
    
    func deleteStoreProductsAndDependenciesSync(realm: Realm, storeProducts: Results<DBStoreProduct>, markForSync: Bool) -> Bool {
        let uuids = storeProducts.map{$0.uuid}
        let listItemResult = realm.objects(DBListItem).filter(DBListItem.createFilterWithProducts(uuids))
        if markForSync {
            let toRemoveListItems = listItemResult.map{DBRemoveListItem($0)}
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        realm.delete(listItemResult)
        
        if markForSync {
            let toRemoveStoreProducts = storeProducts.map{DBStoreProductToRemove($0)}
            saveObjsSyncInt(realm, objs: toRemoveStoreProducts, update: true)
        }
        realm.delete(storeProducts)
        
        return true
    }
}