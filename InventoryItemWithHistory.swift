//
//  InventoryItemWithHistory.swift
//  shoppin
//
//  Created by ischuetz on 13/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

/**
Represents a just added inventory item. Contains the inventory item and additional informacion necessary to construct a history item.
We could as well have created a independent class "BoughtItem" with all needed fields of inventory item and history item, but this is more convenient.
*/
class InventoryItemWithHistoryEntry: Equatable {

    let inventoryItem: InventoryItem
    let historyItemUuid: String
    let paidPrice: Float // product price at the moment of buying the item (per unit)
    let addedDate: NSDate
    
    // the user that added the item. When the user has never logged in, this user is "empty" (empty email). The user is set by the server during sync the first time the user logs in, or registers. This will be in the sync response, so after sync it's also set in the client. The reason we set this in the server is that history is long and the server has to iterate through the input objects anyway, while in the client we would need to iterate only for this or an additional db query between login and sync, which would make sync even slower.
    let user: SharedUser
    
    init(inventoryItem: InventoryItem, historyItemUuid: String, paidPrice: Float, addedDate: NSDate, user: SharedUser) {
        self.inventoryItem = inventoryItem
        self.historyItemUuid = historyItemUuid
        self.paidPrice = paidPrice
        self.addedDate = addedDate
        self.user = user
    }


    convenience init(inventoryItem: InventoryItem, storeProduct: StoreProduct, historyItemUuid: String, addedDate: NSDate, user: SharedUser) {
        self.init(inventoryItem: inventoryItem, historyItemUuid: historyItemUuid, paidPrice: storeProduct.price, addedDate: addedDate, user: user)
    }
    
    func copy(inventoryItem inventoryItem: InventoryItem? = nil, historyItemUuid: String? = nil, paidPrice: Float? = nil, addedDate: NSDate? = nil, user: SharedUser? = nil) -> InventoryItemWithHistoryEntry {
        return InventoryItemWithHistoryEntry(
            inventoryItem: inventoryItem ?? self.inventoryItem,
            historyItemUuid: historyItemUuid ?? self.historyItemUuid,
            paidPrice: paidPrice ?? self.paidPrice,
            addedDate: addedDate ?? self.addedDate,
            user: user ?? self.user
        )
    }
}

func ==(lhs: InventoryItemWithHistoryEntry, rhs: InventoryItemWithHistoryEntry) -> Bool {
    return lhs.historyItemUuid == rhs.historyItemUuid
}