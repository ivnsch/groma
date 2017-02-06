//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

// TODO put these structs somewhere else

public struct ProductUnique {
    let name: String
    let brand: String
    
    init(name: String, brand: String) {
        self.name = name
        self.brand = brand
    }
}

public typealias QuantifiableProductUnique = (name: String, brand: String, unit: ProductUnit, baseQuantity: String)
//public struct QuantifiableProductUnique {
//    let name: String
//    let brand: String
//    let unit: ProductUnit
//    
//    init(name: String, brand: String, unit: ProductUnit) {
//        self.name = name
//        self.brand = brand
//    }
//}

public struct ProductPrototype {
    public var name: String
    public var category: String
    public var categoryColor: UIColor
    public var brand: String
    
    public var baseQuantity: String
    public var unit: ProductUnit

    var productUnique: ProductUnique {
        return ProductUnique(name: name, brand: brand)
    }
    
    var quantifiableProductUnique: QuantifiableProductUnique {
        return QuantifiableProductUnique(name: name, brand: brand, unit: unit, baseQuantity: baseQuantity)
    }
    
    // TODO!!!!!!!!!!!!! remove defaults
    public init(name: String, category: String, categoryColor: UIColor, brand: String, baseQuantity: String = "1", unit: ProductUnit = .none) {
        self.name = name
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}

//public struct StoreProductUnique {
//    let name: String
//    let brand: String
//    let store: String
//    
//    init(name: String, brand: String, store: String) {
//        self.name = name
//        self.brand = brand
//        self.store = store
//    }
//}

class RealmProductProvider: RealmProvider {
    
    func loadProductWithUuid(_ uuid: String, handler: @escaping (Product?) -> ()) {
        do {
            let realm = try Realm()
            // TODO review if it's necessary to pass the sort descriptor here again
            let productMaybe: Product? = self.loadSync(realm, filter: Product.createFilter(uuid)).first
            handler(productMaybe)
            
        } catch let e {
            QL4("Error: creating Realm, returning empty results, error: \(e)")
            handler(nil)
        }
    }
    
    // TODO rename method (uses now brand too)
    func loadProductWithName(_ name: String, brand: String, handler: @escaping (Product?) -> ()) {
        
        background({() -> String? in
            do {
                let realm = try Realm()
                let product: Product? = self.loadSync(realm, filter: Product.createFilterNameBrand(name, brand: brand)).first
                return product?.uuid
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidMaybe in
            do {
                if let productUuid = productUuidMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let productMaybe: Product? = self.loadSync(realm, filter: Product.createFilter(productUuid)).first
                    if productMaybe == nil {
                        QL4("Unexpected: product with just fetched uuid is not there")
                    }
                    handler(productMaybe)
                    
                } else {
                    QL1("No product found for name: \(name), brand: \(brand)")
                    handler(nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }

    func loadProductsWithNameBrands(_ nameBrands: [(name: String, brand: String)], handler: @escaping ([Product]) -> Void) {
        withRealm({realm -> [String]? in
            var productUuids: [String] = []
            for nameBrand in nameBrands {
                let dbProduct: Results<Product> = realm.objects(Product.self).filter(Product.createFilterNameBrand(nameBrand.name, brand: nameBrand.brand))
                productUuids.appendAll(dbProduct.map{$0.uuid})
            }
            return productUuids
        }) {productUuidsMaybe in
            do {
                if let productUuids = productUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let products: Results<Product> = self.loadSync(realm, filter: Product.createFilterUuids(productUuids))
                    handler(products.toArray())
                    
                } else {
                    QL4("No product uuids")
                    handler([])
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler([])
            }
        }
    }

    func loadQuantifiableProductWithUnique(_ unique: QuantifiableProductUnique, handler: @escaping (QuantifiableProduct?) -> Void) {
        
        background({() -> String? in
            do {
                let product: QuantifiableProduct? = self.loadQuantifiableProductWithUniqueSync(unique)
                return product?.uuid
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidMaybe in
            do {
                if let productUuid = productUuidMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let productMaybe: QuantifiableProduct? = self.loadSync(realm, filter: QuantifiableProduct.createFilter(productUuid)).first
                    if productMaybe == nil {
                        QL4("Unexpected: product with just fetched uuid is not there")
                    }
                    handler(productMaybe)
                    
                } else {
                    QL1("No product found for unique: \(unique)")
                    handler(nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }
    
    
    func loadProducts(_ range: NSRange, sortBy: ProductSortBy, handler: @escaping (Results<Product>?) -> ()) {
        // For now duplicate code with products, to use Results and plain objs api together (for search text for now it's easier to use plain obj api)
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        load(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)/*, range: range*/) {(products: Results<Product>?) in
            handler(products)
        }
    }
    
    func loadQuantifiableProducts(_ range: NSRange, sortBy: ProductSortBy, handler: @escaping (Results<QuantifiableProduct>?) -> Void) {
        // For now duplicate code with products, to use Results and plain objs api together (for search text for now it's easier to use plain obj api)
        // TODO? include unit/base quantity in sorting
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("productOpt.name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        load(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)/*, range: range*/) {(products: Results<QuantifiableProduct>?) in
            handler(products)
        }
    }
    
    
    // IMPORTANT: This cannot be used for real time updates (add) since the final results are fetched using uuids, so these results don't notice products with new uuids
    func products(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: Results<Product>?) -> Void) {
        
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{Product.createFilterNameContains($0)}
        
        background({() -> [String]? in
            do {
                let realm = try Realm()
                let products: [Product] = self.loadSync(realm, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
                return products.map{$0.uuid}
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidsMaybe in
            do {
                if let productUuids = productUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let products: Results<Product> = self.loadSync(realm, filter: Product.createFilterUuids(productUuids), sortDescriptor: SortDescriptor(property: sortData.key, ascending: sortData.ascending))
                    handler(substring, products)
                    
                } else {
                    QL4("No product uuids")
                    handler(substring, nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(substring, nil)
            }
        })
    
    }

    // IMPORTANT: This cannot be used for real time updates (add) since the final results are fetched using uuids, so these results don't notice products with new uuids
    // TODO refactor with products() above? (this is a copy with few necessary changes for quantifiable product). Or maybe remove above, since now we need only this?
    func products(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: Results<QuantifiableProduct>?) -> Void) {
        
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("productOpt.name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{QuantifiableProduct.createFilterNameContains($0)}
        
        background({() -> [String]? in
            do {
                let realm = try Realm()
                let products: [QuantifiableProduct] = self.loadSync(realm, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
                return products.map{$0.uuid}
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidsMaybe in
            do {
                if let productUuids = productUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let products: Results<QuantifiableProduct> = self.loadSync(realm, filter: Product.createFilterUuids(productUuids), sortDescriptor: SortDescriptor(property: sortData.key, ascending: sortData.ascending))
                    handler(substring, products)
                    
                } else {
                    QL4("No product uuids")
                    handler(substring, nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(substring, nil)
            }
        })
        
    }
    
    

    func quantifiableProducts(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: [QuantifiableProduct]?) -> Void) {
        products(substring, range: range, sortBy: sortBy) {(substring, result: Results<QuantifiableProduct>?) in
            handler(substring, result?.toArray())
        }
    }
    
    func products(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: [Product]?) -> Void) {
        products(substring, range: range, sortBy: sortBy) {(substring, result) in
            handler(substring, result?.toArray())
        }
    }
    
    func quantifiableProducts(product: Product, handler: @escaping ([QuantifiableProduct]?) -> Void) {
        handler(loadSync(filter: QuantifiableProduct.createFilterProduct(product.uuid))?.toArray())
    }
    
    // TODO range, maybe remove this as we are now using (again) products for this instead of quantifiable products
    func quantifiableProductsWithPosibleSections(_ substring: String? = nil, list: List, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ productsWithMaybeSections: [(product: QuantifiableProduct, section: Section?)]?) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{QuantifiableProduct.createFilterNameContains($0)}
        
        // Note that we are load the sections from db for each range - this could be optimised (load sections only once for all pages) but it shouldn't be an issue since usually there are not a lot of sections and it's performing well.
        
        let list = list.copy() // Fixes Realm acces in incorrect thread exceptions
        
        withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
            let products: Results<QuantifiableProduct> = weakSelf.loadSync(realm, filter: filterMaybe, sortDescriptor: SortDescriptor(keyPath: sortData.key, ascending: sortData.ascending)/*, range: range*/)
            
            let categoryNames = products.map{$0.product.category.name}.distinct()
        
            let sectionsDict: [String: Section] = realm.objects(Section.self).filter(Section.createFilterWithNames(categoryNames, listUuid: list.uuid)).toDictionary{($0.name, $0)}
            
//            let productsWithMaybeSections: [(product: Product, section: Section?)] = products.map {product in
//                let sectionMaybe = sectionsDict[product.category.name]
//                return (product, sectionMaybe)
//            }

            let productsWithMaybeSectionsUuids: [(product: String, section: String?)] = products.map {product in
                let sectionMaybe = sectionsDict[product.product.category.name]
                return (product.uuid, sectionMaybe?.uuid)
            }

            
            return productsWithMaybeSectionsUuids
            
        }, resultHandler: {(productsWithMaybeSectionsUuids: [(product: String, section: String?)]?) in
            do {
                let realm = try Realm()
                let productsWithMaybeSections: [(product: QuantifiableProduct, section: Section?)]? = productsWithMaybeSectionsUuids?.flatMap {productUuid, sectionUuid in
                    if let product = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(productUuid)).first {
                        let section = sectionUuid.flatMap{realm.objects(Section.self).filter(Section.createFilter($0)).first}
                        return (product, section)
                    } else {
                        QL4("Error/Warning: Product for just retrieved uuid is not there")
                        return nil
                    }
                }
                handler(substring, productsWithMaybeSections)
                
            } catch let e {
                QL4("Error retrieving objects for uuids: \(productsWithMaybeSectionsUuids), error: \(e)")
                handler(substring, nil)
            }
        })
    }
    
    
    // TODO range
    func productsWithPosibleSections(_ substring: String? = nil, list: List, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ productsWithMaybeSections: [(product: Product, section: Section?)]?) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{Product.createFilterNameContains($0)}
        
        // Note that we are load the sections from db for each range - this could be optimised (load sections only once for all pages) but it shouldn't be an issue since usually there are not a lot of sections and it's performing well.
        
        let list = list.copy() // Fixes Realm acces in incorrect thread exceptions
        
        withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
            let products: Results<Product> = weakSelf.loadSync(realm, filter: filterMaybe, sortDescriptor: SortDescriptor(keyPath: sortData.key, ascending: sortData.ascending)/*, range: range*/)
            
            let categoryNames = products.map{$0.category.name}.distinct()
            
            let sectionsDict: [String: Section] = realm.objects(Section.self).filter(Section.createFilterWithNames(categoryNames, listUuid: list.uuid)).toDictionary{($0.name, $0)}
            
            //            let productsWithMaybeSections: [(product: Product, section: Section?)] = products.map {product in
            //                let sectionMaybe = sectionsDict[product.category.name]
            //                return (product, sectionMaybe)
            //            }
            
            let productsWithMaybeSectionsUuids: [(product: String, section: String?)] = products.map {product in
                let sectionMaybe = sectionsDict[product.category.name]
                return (product.uuid, sectionMaybe?.uuid)
            }
            
            
            return productsWithMaybeSectionsUuids
            
            }, resultHandler: {(productsWithMaybeSectionsUuids: [(product: String, section: String?)]?) in
                do {
                    let realm = try Realm()
                    let productsWithMaybeSections: [(product: Product, section: Section?)]? = productsWithMaybeSectionsUuids?.flatMap {productUuid, sectionUuid in
                        if let product = realm.objects(Product.self).filter(Product.createFilter(productUuid)).first {
                            let section = sectionUuid.flatMap{realm.objects(Section.self).filter(Section.createFilter($0)).first}
                            return (product, section)
                        } else {
                            QL4("Error/Warning: Product for just retrieved uuid is not there")
                            return nil
                        }
                    }
                    handler(substring, productsWithMaybeSections)
                    
                } catch let e {
                    QL4("Error retrieving objects for uuids: \(productsWithMaybeSectionsUuids), error: \(e)")
                    handler(substring, nil)
                }
        })
    }
    
    func countProducts(_ handler: @escaping (Int?) -> Void) {
        withRealm({realm in
            realm.objects(Product.self).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }
    
    func deleteProductAndDependencies(_ productUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductAndDependenciesSync(realm, productUuid: productUuid, markForSync: markForSync)
            } else {
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func deleteProductsAndDependencies(name: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductsAndDependenciesSync(realm, productName: name, markForSync: markForSync)
            } else {
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func deleteProductsAndDependencies(base: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductsAndDependenciesSync(realm, base: base, markForSync: markForSync)
            } else {
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func deleteProductsAndDependencies(unit: ProductUnit, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductsAndDependenciesSync(realm, unit: unit, markForSync: markForSync)
            } else {
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func deleteProductAndDependencies(_ product: Product, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        deleteProductAndDependencies(product.uuid, markForSync: markForSync, handler: handler)
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductAndDependenciesSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        if let productResult = realm.objects(Product.self).filter(Product.createFilter(productUuid)).first {
            return deleteProductAndDependenciesSync(realm, dbProduct: productResult, markForSync: markForSync)
        } else {
            return false
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductsAndDependenciesSync(_ realm: Realm, productName: String, markForSync: Bool) -> Bool {
        let productsResult = realm.objects(Product.self).filter(Product.createFilterName(productName))
        for product in productsResult {
            deleteProductAndDependenciesSync(realm, dbProduct: product, markForSync: markForSync)
        }
        return true
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductsAndDependenciesSync(_ realm: Realm, base: String, markForSync: Bool) -> Bool {
        let productsResult = realm.objects(Product.self).filter(Product.createFilter(base: base))
        for product in productsResult {
            deleteProductAndDependenciesSync(realm, dbProduct: product, markForSync: markForSync)
        }
        return true
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductsAndDependenciesSync(_ realm: Realm, unit: ProductUnit, markForSync: Bool) -> Bool {
        let productsResult = realm.objects(Product.self).filter(Product.createFilter(unit: unit))
        for product in productsResult {
            deleteProductAndDependenciesSync(realm, dbProduct: product, markForSync: markForSync)
        }
        return true
    }
    
    func deleteProductAndDependenciesSync(_ realm: Realm, dbProduct: Product, markForSync: Bool) -> Bool {
        if deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync) {
            if markForSync {
                let toRemove = ProductToRemove(dbProduct)
                realm.add(toRemove, update: true)
            }
            realm.delete(dbProduct)
            return true
        } else {
            return false
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductDependenciesSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        
        let quantifiableProductsResult = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilterProduct(productUuid))

        for quantifiableProduct in quantifiableProductsResult {
            deleteQuantifiableProductAndDependenciesSync(realm, quantifiableProductUuid: quantifiableProduct.uuid, markForSync: markForSync)
        }
        
        return true
    }
    
    func deleteQuantifiableProductAndDependencies(_ quantifiableProductUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteQuantifiableProductAndDependenciesSync(realm, quantifiableProductUuid: quantifiableProductUuid, markForSync: markForSync)
            } else {
                print("WARN: RealmListItemProvider.deleteProductAndDependencies: self is nil")
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteQuantifiableProductAndDependenciesSync(_ realm: Realm, quantifiableProductUuid: String, markForSync: Bool) -> Bool {
        if let productResult = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(quantifiableProductUuid)).first {
            return deleteQuantifiableProductAndDependenciesSync(realm, dbProduct: productResult, markForSync: markForSync)
        } else {
            return false
        }
    }
    
    func deleteQuantifiableProductAndDependenciesSync(_ realm: Realm, dbProduct: QuantifiableProduct, markForSync: Bool) -> Bool {
        if deleteQuantifiableProductDependenciesSync(realm, quantifiableProductUuid: dbProduct.uuid, markForSync: markForSync) {
            
            // Commented because structural changes - there are no thombstones for quantifiable products as this class is new and it seems we will not use the custom backend anymore
//            if markForSync {
//                let toRemove = ProductToRemove(dbProduct)
//                realm.add(toRemove, update: true)
//            }
            realm.delete(dbProduct)
            return true
        } else {
            return false
        }
    }
    
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteQuantifiableProductDependenciesSync(_ realm: Realm, quantifiableProductUuid: String, markForSync: Bool) -> Bool {
        
        _ = DBProv.storeProductProvider.deleteStoreProductsAndDependenciesForProductSync(realm, productUuid: quantifiableProductUuid, markForSync: markForSync)
        
        _ = DBProv.groupItemProvider.removeGroupItemsForProductSync(realm, productUuid: quantifiableProductUuid, markForSync: markForSync)

        let ingredientsResult = realm.objects(Ingredient.self).filter(Ingredient.createFilterProduct(quantifiableProductUuid))
        // Commented because structural changes - there are no thombstones for quantifiable products as this class is new and it seems we will not use the custom backend anymore
//        if markForSync {
//            let toRemoteInventoryItems = Array(inventoryResult.map{DBRemoveInventoryItem($0)})
//            saveObjsSyncInt(realm, objs: toRemoteInventoryItems, update: true)
//        }
        realm.delete(ingredientsResult)
        
        let inventoryResult = realm.objects(InventoryItem.self).filter(InventoryItem.createFilter(quantifiableProductUuid: quantifiableProductUuid))
        if markForSync {
            let toRemoteInventoryItems = Array(inventoryResult.map{DBRemoveInventoryItem($0)})
            saveObjsSyncInt(realm, objs: toRemoteInventoryItems, update: true)
        }
        realm.delete(inventoryResult)
        
        let historyResult = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(quantifiableProductUuid: quantifiableProductUuid))
        if markForSync {
            let toRemoteHistoryItems =  Array(historyResult.map{DBRemoveHistoryItem($0)})
            saveObjsSyncInt(realm, objs: toRemoteHistoryItems, update: true)
        }
        realm.delete(historyResult)
        
        let planResult = realm.objects(DBPlanItem.self).filter(DBPlanItem.createFilterWithProduct(quantifiableProductUuid))
        if markForSync {
            // TODO plan items either complete or remove this table entirely
        }
        realm.delete(planResult)
        
        return true
    }
    
    
    // Expected to be executed in do/catch and write block
    func removeProductsForCategorySync(_ realm: Realm, categoryUuid: String, markForSync: Bool) -> Bool {
        let dbProducts = realm.objects(Product.self).filter(Product.createFilterCategory(categoryUuid))
        for dbProduct in dbProducts {
            _ = deleteProductAndDependenciesSync(realm, dbProduct: dbProduct, markForSync: markForSync)
        }
        return true
    }
    
    // TODO deprecate this?
    func saveProduct(_ productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: @escaping (Product?) -> ()) {
        
        loadProductWithName(productInput.name, brand: productInput.brand) {[weak self] productMaybe in
            
            if productMaybe.isSet && !update {
                print("Product with name: \(productInput.name), already exists, no update")
                handler(nil)
                return
            }
            
            let uuid: String = {
                if let existingProduct = productMaybe { // since realm doesn't support unique besides primary key yet, we have to fetch first possibly existing product
                    return existingProduct.uuid
                } else {
                    return UUID().uuidString
                }
            }()
            
            Prov.productCategoryProvider.categoryWithName(productInput.category) {result in
                
                if result.status == .success || result.status == .notFound  {
                    
                    // Create a new category or update existing one
                    let category: ProductCategory? = {
                        if let existingCategory = result.sucessResult {
                            return existingCategory.copy(name: productInput.category, color: productInput.categoryColor)
                        } else if result.status == .notFound {
                            return ProductCategory(uuid: UUID().uuidString, name: productInput.category, color: productInput.categoryColor)
                        } else {
                            print("Error: RealmListItemProvider.saveProductError, invalid state: status is .Success but there is not successResult")
                            return nil
                        }
                    }()
                    
                    // Save product with new/updated category
                    if let category = category {
                        let product = Product(uuid: uuid, name: productInput.name, category: category, brand: productInput.brand)
                        self?.saveProducts([product]) {saved in
                            if saved {
                                handler(product)
                            } else {
                                print("Error: RealmListItemProvider.saveProductError, could not save product: \(product)")
                                handler(nil)
                            }
                        }
                    } else {
                        print("Error: RealmListItemProvider.saveProduct, category is nill")
                        handler(nil)
                    }
                    
                } else {
                    print("Error: RealmListItemProvider.saveProduct, couldn't fetch category: \(result)")
                    handler(nil)
                }
            }
        }
    }

    
    func updateOrCreateQuantifiableProduct(_ prototype: ProductPrototype, handler: @escaping (QuantifiableProduct?) -> Void) {

        let productInput = ProductInput(name: prototype.name, category: prototype.category, categoryColor: prototype.categoryColor, brand: prototype.brand)
        updateOrCreateProduct(productInput) {productMaybe in
            
            guard let product = productMaybe else {
                QL4("Couldn't update/create product for prototype: \(prototype)")
                handler(nil)
                return
            }
            
            self.loadQuantifiableProductWithUnique((name: prototype.name, brand: prototype.brand, unit: prototype.unit, baseQuantity: prototype.baseQuantity)) {quantifiableProductMaybe in
             
                if let existingQuantifiableProduct = quantifiableProductMaybe {
                    // nothing to update (there are no fields in quantifiable product that don't belong to unique)
                    handler(existingQuantifiableProduct)

                } else {
                    let newQuantifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantity: prototype.baseQuantity, unit: prototype.unit, product: product)
                    self.doInWriteTransactionSync({realm in
                        realm.add(newQuantifiableProduct)
                    })
                }
            }
        }
    }
    
    
    func updateOrCreateProduct(_ productInput: ProductInput, _ handler: @escaping (Product?) -> Void) {
        
        loadProductWithName(productInput.name, brand: productInput.brand) {[weak self] productMaybe in

            func onHasNewOrUpdatedProduct(product: Product) {
                self?.saveProducts([product], update: true) {saved in
                    if saved {
                        handler(product)
                    } else {
                        QL4("Could not save product: \(product)")
                        handler(nil)
                    }
                }
            }
            
            func onHasNewOrUpdatedCategory(category: ProductCategory) {
                if let existingProduct = productMaybe {
                    let updatedProduct = existingProduct.copy(name: productInput.name, category: category, brand: productInput.brand)
                    onHasNewOrUpdatedProduct(product: updatedProduct)
                    
                } else {
                    let newProduct = Product(uuid: UUID().uuidString, name: productInput.name, category: category, brand: productInput.brand)
                    onHasNewOrUpdatedProduct(product: newProduct)
                }
            }
            
            // seach for existing category with unique (name) and use it or create new one. We don't simply update product's category (in the case where product exists) - imagine e.g. user wants to change the category of a list item, say, "meat" to "fish" - the intent is to assign the item a different category, not to update the category (otherwise the previous "meat" category would now be named "fish" and everything in the app classified as meat would now be fish). For category name update intent, we have (or will have at least) a dedicated screen to manage categories.
            DBProv.productCategoryProvider.category(name: productInput.category) {categoryMaybe in
                let category: ProductCategory = {
                    if let category = categoryMaybe {
                        return category.copy(color: productInput.categoryColor)
                    } else { // category doesn't exist
                        return ProductCategory(uuid: UUID().uuidString, name: productInput.category, color: productInput.categoryColor.hexStr)
                    }
                }()
                
                onHasNewOrUpdatedCategory(category: category)
            }
        }
    }
    
    func saveQuantifiableProducts(_ products: [QuantifiableProduct], update: Bool = true, handler: @escaping (Bool) -> ()) {
    
        let productsCopy = products.map{$0.copy()} // fixes Realm acces in incorrect thread exceptions
        
        for product in productsCopy {
            
            doInWriteTransaction({realm in
                realm.add(product, update: update)
                return true
                
            }, finishHandler: {success in
                handler(success ?? false)
            })
        }
    }
    
    
    func saveProducts(_ products: [Product], update: Bool = true, handler: @escaping (Bool) -> ()) {
        
        let productsCopy = products.map{$0.copy()} // fixes Realm acces in incorrect thread exceptions
        
        for product in productsCopy {
            
            doInWriteTransaction({realm in
                realm.add(product, update: update)
                return true
                
                }, finishHandler: {success in
                    handler(success ?? false)
            })
        }
    }
    
    // TODO: -
    
    func categoriesContaining(_ text: String, handler: @escaping ([String]) -> Void) {
        let mapper: (Product) -> String = {$0.category.name}
        self.load(mapper, filter: Product.createFilterCategoryNameContains(text)) {categories in
            let distinctCategories = NSOrderedSet(array: categories).array as! [String] // TODO re-check: Realm can't distinct yet https://github.com/realm/realm-cocoa/issues/1103
            handler(distinctCategories)
        }
    }

    func productWithUniqueSync(_ realm: Realm, name: String, brand: String) -> Product? {
        return realm.objects(Product.self).filter(Product.createFilterNameBrand(name, brand: brand)).first
    }
    
    func categoryWithName(_ name: String, handler: @escaping (ProductCategory?) -> ()) {
        background({() -> String? in
            do {
                let realm = try Realm()
                let obj: ProductCategory? = self.loadSync(realm, filter: ProductCategory.createFilterName(name)).first
                return obj?.uuid
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {uuidMaybe in
            do {
                if let uuid = uuidMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let objMaybe: ProductCategory? = self.loadSync(realm, filter: ProductCategory.createFilter(uuid)).first
                    if objMaybe == nil {
                        QL4("Unexpected: obj with just fetched uuid is not there")
                    }
                    handler(objMaybe)
                    
                } else {
                    QL1("No category found for name: \(name)")
                    handler(nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }
    
    func loadCategorySuggestions(_ handler: @escaping ([Suggestion]) -> ()) {
        // TODO review why section and product suggestion have their own database objects, was it performance, prefill etc? Do we also need this here?
        self.load {(categories: Results<ProductCategory>?) in
            if let categories = categories {
                let suggestions = Array(categories.map{Suggestion(name: $0.name)})
                handler(suggestions)
            } else {
                QL4("No categories")
                handler([])
            }
        }
    }
    
    func incrementFav(quantifiableProductUuid: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let existingProduct = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(quantifiableProductUuid)).first {
                existingProduct.fav += 1
                realm.add(existingProduct, update: true)                
                return true
            } else { // product not found
                return false
            }
        }, finishHandler: {savedMaybe in
            handler(savedMaybe ?? false)
        })
    }
    
    func save(_ dbCategories: [ProductCategory], dbProducts: [QuantifiableProduct], _ handler: @escaping (Bool) -> Void) {
        
        doInWriteTransaction({realm in
            for dbCategory in dbCategories {
//                print("saving cat: \(dbCategory.uuid)")
                realm.add(dbCategory, update: false)
            }
            for dbProduct in dbProducts {
//                print("saving prod: \(dbProduct.uuid)")
                realm.add(dbProduct, update: true) // update: true: apparently the product tries to save again its category and with update: false this results in a duplicate (category) uuid exception!
            }
            return true
            
            }, finishHandler: {(savedMaybe: Bool?) in
                let saved: Bool = savedMaybe.map{$0} ?? false
                if !saved {
                    print("Error: RealmProductProvider.save: couldn't save")
                }
                handler(saved)
        })
    }
    
    func removeAllCategories(_ handler: @escaping (Bool) -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllCategories: couldn't remove categories")
            }
            handler(success)
        }, objType: ProductCategory.self)
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // WARN: This is only used for generating prefill database so no tombstones
    ///////////////////////////////////////////////////////////////////////////////////////
    
    func removeAllProducts(_ handler: @escaping (Bool) -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllProducts: couldn't remove products")
            }
            handler(success)
        }, objType: Product.self)
    }
    
    // Removes all products and categories
    func removeAllProductsAndCategories(_ handler: @escaping (Bool) -> Void) {
        removeAllProducts {[weak self] success in
            if let weakSelf = self {
                weakSelf.removeAllCategories {success in
                    handler(success)
                }
            } else {
                print("Error: RealmProductProvider.removeAllProductsAndCategories: weakSelf is nil")
                handler(false)
            }

        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    func overwriteProducts(_ dbProducts: [Product], clearTombstones: Bool, handler: @escaping (Bool) -> Void) {
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(ProductToRemove.self)} : nil
        self.overwrite(dbProducts, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    /**
     * Performs an upsert using a product prototype.
     * This will insert a new product if there's no product with the prototype's unique (name+brand+store). Otherwise it updates the existing one.
     * Analogously for the category, inserts a new one if no one exists with the prototype's category name, or updates the existing one.
     * Ensures that the product points to the correct category which can be 1. The same which already was referenced by the product, if the product exists and the category name is unchanged, 2. An existing category which was not referenced by the product (input category name is different than the name of the category referenced by the existing product), 3. A new category, if no category with prototype's category name exists yet.
     */
    func upsertProductSync(_ realm: Realm, prototype: ProductPrototype) -> Product {
        
        func findOrCreateCategory(_ realm: Realm, prototype: ProductPrototype) -> ProductCategory {
            return realm.objects(ProductCategory.self).filter(ProductCategory.createFilterName(prototype.category)).first ?? ProductCategory(uuid: NSUUID().uuidString, name: prototype.name, color: prototype.categoryColor)
        }
        
        func categoryForExistingProduct(_ existingProduct: Product, prototype: ProductPrototype) -> ProductCategory {
            // Make the updated product point to correct category - if category name hasn't changed, no pointer update. If input category name is different, see if a category with this name already exists, and update pointer. Otherwise create a new category and udpate pointer.
            if existingProduct.category.name != prototype.category {
                return findOrCreateCategory(realm, prototype:  prototype)
            } else {
                return existingProduct.category
            }
        }
        
        func updateExistingProduct(_ realm: Realm, existingProduct: Product, prototype: ProductPrototype) -> Product {
            
            let category = categoryForExistingProduct(existingProduct, prototype: prototype)
            let updatedCategory = category.copy(color: prototype.categoryColor)
            
            // Udpate product fields
            let updatedProduct = existingProduct.update(prototype)
            updatedProduct.category = updatedCategory
            
            realm.add(updatedProduct, update: true)
            
            return updatedProduct
        }
        
        func insertNewProduct(_ realm: Realm, prototype: ProductPrototype) -> Product {
            let category = findOrCreateCategory(realm, prototype: prototype)
            let newProduct = Product(prototype: prototype, category: category)
            realm.add(newProduct, update: false)
            return newProduct
        }
        
        if let existingProduct = realm.objects(Product.self).filter(Product.createFilter(unique: prototype.productUnique)).first {
            return updateExistingProduct(realm, existingProduct: existingProduct, prototype: prototype)
        } else {
            return insertNewProduct(realm, prototype: prototype)
        }
    }
    
    // MARK: - Sync
    
    func clearProductTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(ProductToRemove.self, ProductToRemove.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    
    func updateLastSyncTimeStampSync(_ realm: Realm, product: RemoteProduct) {
        realm.create(Product.self, value: product.timestampUpdateDict, update: true)
    }
    
    // MARK: - Store
    
    func storesContainingText(_ text: String, handler: @escaping ([String]) -> Void) {
        // this is for now an "infinite" range. This method is ussed for autosuggestions, we assume use will not have more than 10000 brands. If yes it's not critical for autosuggestions.
        storesContainingText(text, range: NSRange(location: 0, length: 10000), handler)
    }
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping ([String]) -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("store", ascending: true)
                let stores = Array(Set(realm.objects(StoreProduct.self).filter(StoreProduct.createFilterStoreContains(text)).map{$0.store}))[range].filter{!$0.isEmpty}.sorted()
                return stores
            } catch let e {
                QL4("Couldn't load stores, returning empty array. Error: \(e)")
                return []
            }
            }) {(result: [String]) in
                handler(result)
        }
    }
    
    // Returns: true if restored a product, false if didn't restore a product, nil if error ocurred
    func restorePrefillProducts(_ handler: @escaping (Bool?) -> Void) {
        
        doInWriteTransaction({realm in
            
            let prefillProducts = SuggestionsPrefiller().prefillProducts(LangManager().appLang).products
            
            var restoredSomething: Bool = false
            
            for prefillProduct in prefillProducts {
                if realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(unique: prefillProduct.unique)).isEmpty {
                    QL1("Restoring prefill product: \(prefillProduct)")
                    realm.add(prefillProduct, update: false)
                    restoredSomething = true
                }
            }
            return restoredSomething
            
            }, finishHandler: {successMaybe in
                handler(successMaybe)
        })
    }
    
    func allUnits(_ handler: @escaping ([ProductUnit]?) -> Void) {
        withRealm({(realm) -> [ProductUnit] in
            let units = realm.objects(QuantifiableProduct.self).flatMap{quantifiableProduct in
                return ProductUnit(rawValue: quantifiableProduct.unitVal) ?? {
                    QL4("No product unit for raw value: \(quantifiableProduct.unitVal). Skipping.")
                    return nil
                }()
            }
            return Array(units).distinct()
            
        }) { unitsMaybe in
            if unitsMaybe == nil {
                QL4("Couldn't retrieve units")
            }
            handler(unitsMaybe ?? [])
        }
    }
    
    func allBaseQuantities(_ handler: @escaping ([String]?) -> Void) {
        withRealm({(realm) -> [String] in
            let baseQuanties = realm.objects(QuantifiableProduct.self).flatMap{quantifiableProduct in
                quantifiableProduct.baseQuantity
            }
            return Array(baseQuanties).distinct()
            
        }) { baseQuantiesMaybe in
            if baseQuantiesMaybe == nil {
                QL4("Couldn't retrieve base quantities")
            }
            handler(baseQuantiesMaybe ?? [])
        }
    }
    
    func baseQuantitiesContainingText(_ text: String, _ handler: @escaping ([String]) -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("baseQuantity", ascending: true)
                let baseQuantities = Array(Set(realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilterBaseQuantityContains(text)).map{$0.baseQuantity})).sorted()
                return baseQuantities
            } catch let e {
                QL4("Couldn't load stores, returning empty array. Error: \(e)")
                return []
            }
        }) {(result: [String]) in
            handler(result)
        }
    }
    
    func unitsContainingText(_ text: String, _ handler: @escaping ([String]) -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("unitVal", ascending: true)
                let baseQuantities = Array(Set(realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilterBaseQuantityContains(text)).flatMap{ProductUnit(rawValue: $0.unitVal)})).map{$0.shortText}.sorted()
                return baseQuantities
            } catch let e {
                QL4("Couldn't load stores, returning empty array. Error: \(e)")
                return []
            }
        }) {(result: [String]) in
            handler(result)
        }
    }
    
    // MARK: - Sync
    
    func loadProductWithUniqueSync(_ unique: ProductUnique) -> Product? {
        return withRealmSync {(realm) -> Product? in
            return self.loadSync(realm, filter: Product.createFilter(unique: unique)).first
        }
    }
    
    func loadQuantifiableProductWithUniqueSync(_ unique: QuantifiableProductUnique) -> QuantifiableProduct? {
        return withRealmSync {(realm) -> QuantifiableProduct? in
            return self.loadSync(realm, filter: QuantifiableProduct.createFilter(unique: unique)).first
        }
    }
    
    func mergeOrCreateeProductSync(prototype: ProductPrototype, updateCategory: Bool, save: Bool) -> ProvResult<Product, DatabaseError> {
    
        if let existingProduct = loadProductWithUniqueSync(prototype.productUnique) {
            return .ok(existingProduct.updateNonUniqueProperties(prototype: prototype))
            
        } else {
            let result: ProvResult<Product, DatabaseError> = DBProv.productCategoryProvider.mergeOrCreateCategorySync(name: prototype.category, color: prototype.categoryColor, save: false).map {category in
                return Product(uuid: UUID().uuidString, name: prototype.name, category: category, brand: prototype.brand)
            }
            
            return !save ? result : result.flatMap {product in
                let writeSuccess: Bool? = self.doInWriteTransactionSync({realm in
                    realm.add(product, update: true)
                    return true
                })
                return (writeSuccess ?? false) ? .ok(product) : .err(.unknown)
            }
        }
    }
    
    // Similar to mergeOrCreateProductSync in product provider except: 1. This method does actually save the created/merged product, 2. Synchronous, so it can be executed as part of a write transaction.
    func mergeOrCreateQuantifiableProductSync(prototype: ProductPrototype, updateCategory: Bool, save: Bool) -> ProvResult<QuantifiableProduct, DatabaseError> {
        
        if let existingProduct = loadQuantifiableProductWithUniqueSync(prototype.quantifiableProductUnique) {
            let updatedProduct = existingProduct.product.updateNonUniqueProperties(prototype: prototype)
            let updatedQuantifiableProduct = existingProduct.copy(baseQuantity: prototype.baseQuantity, unit: prototype.unit, product: updatedProduct) // NOTE this does update unique properties TODO!!!!!!!!!!!!!!!! review
            return .ok(updatedQuantifiableProduct)

        } else {
            let result: ProvResult<QuantifiableProduct, DatabaseError> = mergeOrCreateeProductSync(prototype: prototype, updateCategory: true, save: false).map {product in
                return QuantifiableProduct(uuid: UUID().uuidString, baseQuantity: prototype.baseQuantity, unit: prototype.unit, product: product)
            }

            return !save ? result : result.flatMap {product in
                let writeSuccess: Bool? = self.doInWriteTransactionSync({realm in
                    realm.add(product, update: true)
                    return true
                })
                return (writeSuccess ?? false) ? .ok(product) : .err(.unknown)
            }
        }
    }
}
