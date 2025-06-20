//
//  RemoteStoreProduct.swift
//  shoppin
//
//  Created by ischuetz on 07/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteStoreProduct: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let price: Float
    let baseQuantity: Float
    let unit: Int
    let store: String
    let productUuid: String
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let price = representation.value(forKeyPath: "price") as? Float,
            let baseQuantity = representation.value(forKeyPath: "baseQuantity") as? Float,
            let unit = representation.value(forKeyPath: "unit") as? Int,
            let store = representation.value(forKeyPath: "store") as? String,
            let productUuid = representation.value(forKeyPath: "productUuid") as? String,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.store = store
        self.productUuid = productUuid
        self.lastUpdate = Int64(lastUpdate)
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteStoreProduct]? {
        var products = [RemoteStoreProduct]()
        for obj in representation {
            if let product = RemoteStoreProduct(representation: obj) {
                products.append(product)
            } else {
                return nil
            }
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), price: \(price), baseQuantity: \(baseQuantity), unit: \(unit), store: \(store), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteStoreProduct {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
