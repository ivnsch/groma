//
//  RemoteProduct.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteProduct: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let name: String
    public var categoryUuid: String
    public let fav: Int
    public let brand: String
    public let lastUpdate: Int64

    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let name = representation.value(forKeyPath: "name") as? String,
            let categoryUuid = representation.value(forKeyPath: "categoryUuid") as? String,
            let fav = representation.value(forKeyPath: "fav") as? Int,
            let brand = representation.value(forKeyPath: "brand") as? String,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.categoryUuid = categoryUuid
        self.fav = fav
        self.brand = brand
        self.lastUpdate = Int64(lastUpdate)
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteProduct]? {
        var products = [RemoteProduct]()
        for obj in representation {
            if let product = RemoteProduct(representation: obj) {
                products.append(product)
            } else {
                return nil
            }
        }
        return products
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), categoryUuid: \(categoryUuid), fav: \(fav), brand: \(brand), listUpdate: \(lastUpdate)}"
    }
}

public extension RemoteProduct {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
