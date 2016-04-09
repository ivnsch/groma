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
    var categoryUuid: String
    let fav: Int
    let brand: String
    let lastUpdate: NSDate

    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let categoryUuid = representation.valueForKeyPath("categoryUuid") as? String,
            let fav = representation.valueForKeyPath("fav") as? Int,
            let brand = representation.valueForKeyPath("brand") as? String,
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.categoryUuid = categoryUuid
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
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), categoryUuid: \(categoryUuid), fav: \(fav), brand: \(brand), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteProduct {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
    }
}