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
    
    func brands(handler: [String] -> Void) {
        do {
            let realm = try Realm()
            let brands = Array(Set(realm.objects(DBProduct).map{$0.brand})).filter{!$0.isEmpty}
            handler(brands)
        } catch let e {
            print("Error: RealmListItemProvider.brands: Couldn't load brands, returning empty array. Error: \(e)")
            handler([])
        }
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
    
    
    func updateBrand(oldName: String, newName: String, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(DBProduct).filter("brand == '\(oldName)'")
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
    
    func brandsContainingText(text: String, _ handler: [String] -> Void) {
        do {
            let realm = try Realm()
            let brands = Array(Set(realm.objects(DBProduct).filter("brand CONTAINS[c] '\(text)'").map{$0.brand}))
            handler(brands)
        } catch let e {
            print("Error: RealmListItemProvider.brandsContainingText: Couldn't load brands, returning empty array. Error: \(e)")
            handler([])
        }
        
    }
}