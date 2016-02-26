//
//  RemoteProduct.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteProduct: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let price: Float
    var categoryUuid: String
    let baseQuantity: Float
    let unit: Int
    let fav: Int
    let brand: String
    let lastUpdate: NSDate

    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let price = representation.valueForKeyPath("price") as? Float,
            let categoryUuid = representation.valueForKeyPath("categoryUuid") as? String,
            let baseQuantity = representation.valueForKeyPath("baseQuantity") as? Float,
            let unit = representation.valueForKeyPath("unit") as? Int,
            let fav = representation.valueForKeyPath("fav") as? Int,
            let brand = representation.valueForKeyPath("brand") as? String,
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.price = price
        self.categoryUuid = categoryUuid
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.fav = fav
        self.brand = brand
        self.lastUpdate = lastUpdate
    }
    
    static func collection(representation: AnyObject) -> [RemoteProduct]? {
        var products = [RemoteProduct]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProduct(representation: obj) {
                products.append(product)
            } else {
                return nil
            }
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), price: \(price), categoryUuid: \(categoryUuid), baseQuantity: \(baseQuantity), unit: \(unit), fav: \(fav), brand: \(brand), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteProduct {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
    }
}