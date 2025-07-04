//
//  RealmStoreProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class RealmStoreProductProvider: RealmProvider {
      
    func storeProduct(_ uuid: String, handler: @escaping (StoreProduct?) -> Void) {
        handler(loadFirstSync(predicate: StoreProduct.createFilter(uuid)))
    }
    
    func storeProductSync(uuid: String) -> StoreProduct? {
        return loadFirstSync(predicate: StoreProduct.createFilter(uuid))
    }


    func storeProductSync(quantifiableProductUnique: QuantifiableProductUnique, list: List) -> StoreProduct? {
        return loadFirstSync(predicate: StoreProduct.createFilter(unique: quantifiableProductUnique, store: list.store ?? ""))
    }

    func storeProduct(_ product: QuantifiableProduct, store: String, handler: @escaping (StoreProduct?) -> Void) {
        handler(storeProductSync(product, store: store))
    }
    
    func storeProductSync(product: QuantifiableProduct, store: String) -> StoreProduct? {
        return loadFirstSync(predicate: StoreProduct.createFilterProductStore(quantifiableProductUuid: product.uuid, store: store))
    }
    
    func storeProductsSync(_ products: [QuantifiableProduct], store: String) -> Results<StoreProduct>? {
        return loadSync(predicate: StoreProduct.createFilterProductsStores(products, store: store), sortDescriptor: nil)
        
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
        let listItemResult = realm.objects(ListItem.self).filter(ListItem.createFilterWithStoreProducts(uuids))
        if markForSync {
            let toRemoveListItems = Array(listItemResult.map{DBRemoveListItem($0)})
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        realm.delete(listItemResult)

        // After removing list items some sections may be empty - remove them too
        let sectionsResult = realm.objects(Section.self).filter(Section.createFilterListItemsIsEmpty())
        realm.delete(sectionsResult)

        if markForSync {
            let toRemoveStoreProducts = Array(storeProducts.map{StoreProductToRemove($0)})
            saveObjsSyncInt(realm, objs: toRemoveStoreProducts, update: true)
        }
        realm.delete(storeProducts)
        
        return true
    }

    func mostCompleteProductMatchSync(itemName: String, list: List) -> MostCompleteItemMatch {

        // TODO finer logic - at least for siri usage - if we find 1 product (or store product etc) with a different unique - we use this
        // if we find more than 1, or none - we use the default unique (like above with base quantity 1 etc)
        // currently if user has, say, grapes 500g in list we will add a new list item grapes 1 unit.
        let quantifiableProductUnique = QuantifiableProductUnique(
            name: itemName,
            brand: "",
            unit: noneUnitName,
            baseQuantity: 1,
            secondBaseQuantity: 1)

        if let listItem = DBProv.listItemProvider.findListItemWithUniqueSync(quantifiableProductUnique, list: list) {
            return .listItem(listItem: listItem)

        } else if let storeProduct = storeProductSync(quantifiableProductUnique: quantifiableProductUnique, list: list) {
            return .storeProduct(storeProduct: storeProduct)

        } else if let quantifiableProduct = DBProv.productProvider.loadQuantifiableProductWithUniqueSync(
            quantifiableProductUnique
        ) {
            return .quantifiableProduct(quantifiablProduct: quantifiableProduct)

        } else if let product = DBProv.productProvider.loadProductWithUniqueSync(
            ProductUnique(
                name: itemName,
                brand: quantifiableProductUnique.brand
            )) {
            return .product(product: product)

        } else {
            switch DBProv.itemProvider.findSync(name: quantifiableProductUnique.name) {
            case .ok(let item):
                if let item = item {
                    return .item(item: item)
                } else {
                    return .none
                }
            case .err(let error):
                logger.e("Error fetching item: \(error)", .db)
                return .none
            }
        }
    }
    
    // MARK: - Sync
    
    func storeProductSync(_ product: QuantifiableProduct, store: String) -> StoreProduct? {
        return loadFirstSync(predicate: StoreProduct.createFilterProductStore(quantifiableProductUuid: product.uuid, store: store))
    }
    
    func deleteStoreProductSync(uuid: String) -> Bool {
        return doInWriteTransactionSync {[weak self] realm in
            _ = self?.deleteStoreProductsAndDependenciesForProductSync(realm, productUuid: uuid, markForSync: true)
            return true
        } ?? false
    }
}
