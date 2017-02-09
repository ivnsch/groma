//
//  RealmBrandProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

class RealmBrandProvider: RealmProvider {
    
    // Note we don't use loading methods in superclass since these require mapper and brands currently are only strings. Maybe later we can implement methods that don't require mappers.
    
    func brandsContainingText(_ text: String, handler: @escaping ([String]) -> Void) {
        // this is for now an "infinite" range. This method is ussed for autosuggestions, we assume use will not have more than 10000 brands. If yes it's not critical for autosuggestions.
        brandsContainingText(text, range: NSRange(location: 0, length: 10000), handler)
    }
    
    func brands(_ range: NSRange, handler: @escaping ([String]) -> Void) {
        do {
            let realm = try Realm()
            // Note: range is at application level - we are loading all the brands from the database. Currently doesn't seem to be a way to do this at db level
            // we could take range from db results object, problem is that we first have to do "distinct" on product names - which is not supported by realm yet, so we have to load first everything into memory, do distinct and *then* slice to get the correct count.
            let brands = Array(Set(realm.objects(Product.self).map{$0.brand}))[range].filter{!$0.isEmpty}
            handler(brands)
        } catch let e {
            print("Error: RealmListItemProvider.brands: Couldn't load brands, returning empty array. Error: \(e)")
            handler([])
        }
    }

    
    /// Returns all the brands of products with a specified name
    func brands(productName: String, handler: @escaping ([String]?) -> Void) {
        withRealm({realm -> [String] in
            return Array(Set(realm.objects(Product.self).filter(Product.createFilterName(productName)).map{$0.brand}))
        }) {brandsMaybe in
            handler(brandsMaybe)
        }
    }
    
    func removeProductsWithBrand(_ brandName: String, markForSync: Bool, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(Product.self).filter(Product.createFilterBrand(brandName))
            for dbProduct in dbProducts {
                _ = DBProv.productProvider.deleteProductAndDependenciesSync(realm, dbProduct: dbProduct, markForSync: markForSync)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func updateBrand(_ oldName: String, newName: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(Product.self).filter(Product.createFilterBrand(oldName))
            for dbProduct in dbProducts {
                dbProduct.brand = newName
                realm.add(dbProduct, update: true)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func removeBrand(_ name: String, _ handler: @escaping (Bool) -> Void) {
        updateBrand(name, newName: "", handler)
    }
    
    func brandsContainingText(_ text: String, range: NSRange, _ handler: @escaping ([String]) -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("brand", ascending: true)
                let brands = Array(Set(realm.objects(Product.self).filter(Product.createFilterBrandContains(text)).map{$0.brand}))[range].filter{!$0.isEmpty}.sorted()
                return brands
            } catch let e {
                print("Error: RealmListItemProvider.brandsContainingText: Couldn't load brands, returning empty array. Error: \(e)")
                return []
            }
        }) {(result: [String]) in
            handler(result)
        }
    }
    
    /// Returns ingredient uuid : associated brands
    func brands(ingredients: Results<Ingredient>, handler: @escaping ([String: [String]]?) -> Void) {
        let tuples: [(String, String)] = ingredients.map{($0.uuid, $0.item.name)} // fixes realm thread exception
        
        withRealm({realm in
            var ingredientsDict = Dictionary<String, [String]>()
            for tuple in tuples {
                let brands: [String] = Array(Set(realm.objects(Product.self).filter(Product.createFilterName(tuple.1)).map{$0.brand}))
                ingredientsDict[tuple.0] = brands
            }
            return ingredientsDict
        }) {brandsMaybe in
            handler(brandsMaybe)
        }
    }
}
