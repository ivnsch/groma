//
//  RemoteStoreProduct.swift
//  shoppin
//
//  Created by ischuetz on 07/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

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
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let price = representation.valueForKeyPath("price") as? Float,
            let baseQuantity = representation.valueForKeyPath("baseQuantity") as? Float,
            let unit = representation.valueForKeyPath("unit") as? Int,
            let store = representation.valueForKeyPath("store") as? String,
            let productUuid = representation.valueForKeyPath("productUuid") as? String,
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.store = store
        self.productUuid = productUuid
        self.lastUpdate = Int64(lastUpdate)
    }
    
    static func collection(representation: AnyObject) -> [RemoteStoreProduct]? {
        var products = [RemoteStoreProduct]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteStoreProduct(representation: obj) {
                products.append(product)
            } else {
                return nil
            }
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), price: \(price), baseQuantity: \(baseQuantity), unit: \(unit), store: \(store), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteStoreProduct {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}