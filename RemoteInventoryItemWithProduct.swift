//
//  RemoteInventoryItemWithProduct.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteInventoryItemWithProduct: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let inventoryItem: RemoteInventoryItem
    let product: RemoteProduct
    
    init(inventoryItem: RemoteInventoryItem, product: RemoteProduct) {
        self.inventoryItem = inventoryItem
        self.product = product
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let inventoryItem: AnyObject = representation.valueForKeyPath("inventoryItem")!
        self.inventoryItem = RemoteInventoryItem(response: response, representation: inventoryItem)!

        let product: AnyObject = representation.valueForKeyPath("product")!
        self.product = RemoteProduct(response: response, representation: product)!
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryItemWithProduct] {
        var items = [RemoteInventoryItemWithProduct]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteInventoryItemWithProduct(response: response, representation: obj) {
                items.append(item)
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryItem: \(self.inventoryItem), product: \(self.product)}"
    }
}