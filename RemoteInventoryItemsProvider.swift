//
//  RemoteInventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet

class RemoteInventoryItemsProvider: Any {
    
    func inventoryItems(inventory: Inventory, handler: RemoteResult<[RemoteInventoryItemWithProduct]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.inventoryItems, ["inventory": inventory.uuid]) {result in
            handler(result)
        }
    }
    
    func addToInventory(inventory: Inventory, inventoryItems: [InventoryItemWithHistoryEntry], handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = inventoryItems.map{[weak self] in self!.toDictionary($0)}
        RemoteProvider.authenticatedRequest(.POST, Urls.inventoryItems + "/\(inventory.uuid)", parameters) {result in
            handler(result)
        }
    }

    func removeInventoryItem(inventoryItem: InventoryItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = ["productUuid": inventoryItem.product.uuid, "inventoryUuid": inventoryItem.inventory.uuid]
        RemoteProvider.authenticatedRequest(.DELETE, Urls.inventoryItem, parameters) {result in
            handler(result)
        }
    }
    
    func incrementInventoryItem(inventoryItem: InventoryItem, delta: Int, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params: [String: AnyObject] = [
            "delta": delta,
            "productUuid": inventoryItem.product.uuid,
            "inventoryUuid": inventoryItem.inventory.uuid
        ]
        RemoteProvider.authenticatedRequest(.POST, Urls.incrementInventoryItem, params) {result in
            handler(result)
        }
    }
    
    // TODO remote inventory from inventory items, at least for sending - we want to add all the items to one inventory....... for receiving this also wastes payload, they also have the same inventory also
    private func toDictionary(inventoryItem: InventoryItemWithHistoryEntry) -> [String: AnyObject] {
        return [
            "product": [
                "uuid": inventoryItem.inventoryItem.product.uuid,
                "name": inventoryItem.inventoryItem.product.name,
                "price": inventoryItem.inventoryItem.product.price
            ],
            "inventoryItem": [
                "quantity": inventoryItem.inventoryItem.quantityDelta,
                "inventoryUuid": inventoryItem.inventoryItem.inventory.uuid,
                "productUuid": inventoryItem.inventoryItem.product.uuid
            ],
            "historyItemUuid": inventoryItem.historyItemUuid,
            "addedDate": NSNumber(double: inventoryItem.addedDate.timeIntervalSince1970).longValue,
            "user": self.toRequestParams(inventoryItem.user)
        ]
    }
    
    private func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
}
