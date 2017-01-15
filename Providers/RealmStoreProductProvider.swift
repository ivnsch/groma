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
        handler(loadFirstSync(filter: StoreProduct.createFilter(uuid)))
    }
    
    func storeProductSync(uuid: String) -> StoreProduct? {
        return loadFirstSync(filter: StoreProduct.createFilter(uuid))
    }

    func storeProduct(_ product: QuantifiableProduct, store: String, handler: @escaping (StoreProduct?) -> Void) {
        handler(loadFirstSync(filter: StoreProduct.createFilterProductStore(quantifiableProductUuid: product.uuid, store: store)))
    }
    
    func storeProductSync(product: QuantifiableProduct, store: String) -> StoreProduct? {
        return loadFirstSync(filter: StoreProduct.createFilterProductStore(quantifiableProductUuid: product.uuid, store: store))
    }
    
    func storeProductsSync(_ products: [QuantifiableProduct], store: String) -> Results<StoreProduct>? {
        return loadSync(filter: StoreProduct.createFilterProductsStores(products, store: store), sortDescriptor: nil)
        
//        return withRealmSync {[weak self] realm in
//            let mapper = {StoreProductMapper.productWithDB($0)}
//            return self?.loadSync(realm, mapper: mapper, filter: StoreProduct.createFilterProductsStores(products, store: store))
//        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteStoreProductDependenciesSync(_ realm: Realm, storeProductUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(StoreProduct.self).filter(StoreProduct.createFilter(storeProductUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }

    func deleteStoreProductsAndDependenciesForProductSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let storeProductResult = realm.objects(StoreProduct.self).filter(StoreProduct.createFilterProduct(productUuid))
        return deleteStoreProductsAndDependenciesSync(realm, storeProducts: storeProductResult, markForSync: markForSync)
    }
    
    func deleteStoreProductsAndDependenciesSync(_ realm: Realm, storeProducts: Results<StoreProduct>, markForSync: Bool) -> Bool {
        let uuids = Array(storeProducts.map{$0.uuid})
        let listItemResult = realm.objects(ListItem.self).filter(ListItem.createFilterWithProducts(uuids))
        if markForSync {
            let toRemoveListItems = Array(listItemResult.map{DBRemoveListItem($0)})
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        realm.delete(listItemResult)
        
        if markForSync {
            let toRemoveStoreProducts = Array(storeProducts.map{StoreProductToRemove($0)})
            saveObjsSyncInt(realm, objs: toRemoveStoreProducts, update: true)
        }
        realm.delete(storeProducts)
        
        return true
    }
}
