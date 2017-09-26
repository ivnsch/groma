//
//  RemoteListNoUsers.swift
//  shoppin
//
//  Created by ischuetz on 24/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteListNoUsers: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let name: String
    public let order: Int
    public var color: UIColor
    public var store: String?
    public let lastUpdate: Int64
    public let inventoryUuid: String
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let name = representation.value(forKeyPath: "name") as? String,
            let order = representation.value(forKeyPath: "order") as? Int,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double,
            let inventoryUuid = representation.value(forKeyPath: "inventoryUuid") as? String,
            let color = ((representation.value(forKeyPath: "color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            })
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        self.uuid = uuid
        self.name = name
        self.order = order
        self.lastUpdate = Int64(lastUpdate)
        self.inventoryUuid = inventoryUuid
        self.color = color
        
        if let storeMaybe = representation.value(forKeyPath: "store") {
            if let store = storeMaybe as? String {
                self.store = store
            } else {
                logger.e("Invalid store type: \(storeMaybe)")
                return nil
            }
        }
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteListNoUsers]? {
        var lists = [RemoteListNoUsers]()
        for obj in representation {
            if let list = RemoteListNoUsers(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), order: \(order), inventoryUuid: \(inventoryUuid), lastUpdate: \(lastUpdate), color: \(color), store: \(String(describing: store))}"
    }
}
