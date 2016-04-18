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
    
    func brandsContainingText(text: String, handler: [String] -> Void) {
        // this is for now an "infinite" range. This method is ussed for autosuggestions, we assume use will not have more than 10000 brands. If yes it's not critical for autosuggestions.
        brandsContainingText(text, range: NSRange(location: 0, length: 10000), handler)
    }
    
    func brands(range: NSRange, handler: [String] -> Void) {
        do {
            let realm = try Realm()
            // Note: range is at application level - we are loading all the brands from the database. Currently doesn't seem to be a way to do this at db level
            // we could take range from db results object, problem is that we first have to do "distinct" on product names - which is not supported by realm yet, so we have to load first everything into memory, do distinct and *then* slice to get the correct count.
            let brands = Array(Set(realm.objects(DBProduct).map{$0.brand}))[range].filter{!$0.isEmpty}
            handler(brands)
        } catch let e {
            print("Error: RealmListItemProvider.brands: Couldn't load brands, returning empty array. Error: \(e)")
            handler([])
        }
    }
    
    func removeProductsWithBrand(brandName: String, markForSync: Bool, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(DBProduct).filter(DBProduct.createFilterBrand(brandName))
            for dbProduct in dbProducts {
                DBProviders.productProvider.deleteProductAndDependenciesSync(realm, dbProduct: dbProduct, markForSync: markForSync)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func updateBrand(oldName: String, newName: String, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(DBProduct).filter(DBProduct.createFilterBrand(oldName))
            for dbProduct in dbProducts {
                dbProduct.brand = newName
                realm.add(dbProduct, update: true)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func removeBrand(name: String, _ handler: Bool -> Void) {
        updateBrand(name, newName: "", handler)
    }
    
    func brandsContainingText(text: String, range: NSRange, _ handler: [String] -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("brand", ascending: true)
                let brands = Array(Set(realm.objects(DBProduct).filter(DBProduct.createFilterBrandContains(text)).map{$0.brand}))[range].filter{!$0.isEmpty}.sort()
                return brands
            } catch let e {
                print("Error: RealmListItemProvider.brandsContainingText: Couldn't load brands, returning empty array. Error: \(e)")
                return []
            }
        }) {(result: [String]) in
            handler(result)
        }
    }
}