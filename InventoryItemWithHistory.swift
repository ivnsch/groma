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
    let addedDate: NSDate
    let user: SharedUser // the user that added the item. This is normally the current logged in user. We don't want to make assumptions though about it, maybe at some point we could allow a user to add inventory items "in name of" other of the shared users, or something like that.
    
    init(inventoryItem: InventoryItem, historyItemUuid: String, addedDate: NSDate, user: SharedUser) {
        self.inventoryItem = inventoryItem
        self.historyItemUuid = historyItemUuid
        self.addedDate = addedDate
        self.user = user
    }
    
    func copy(inventoryItem inventoryItem: InventoryItem? = nil, historyItemUuid: String? = nil, addedDate: NSDate? = nil, user: SharedUser? = nil) -> InventoryItemWithHistoryEntry {
        return InventoryItemWithHistoryEntry(
            inventoryItem: inventoryItem ?? self.inventoryItem,
            historyItemUuid: historyItemUuid ?? self.historyItemUuid,
            addedDate: addedDate ?? self.addedDate,
            user: user ?? self.user
        )
    }
}

func ==(lhs: InventoryItemWithHistoryEntry, rhs: InventoryItemWithHistoryEntry) -> Bool {
    return lhs.historyItemUuid == rhs.historyItemUuid
}