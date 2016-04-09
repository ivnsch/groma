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
}
