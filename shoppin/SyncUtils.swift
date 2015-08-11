//
//  SyncUtils.swift
//  shoppin
//
//  Created by ischuetz on 07/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// For now putting common sync functionality in utils class
// TODO refactor!!
struct SyncUtils {

    /**
    Separates listItems that are marked for removal from the rest
    And collects listItems from "rest" which are new or have been updated
    
    :returns: tuple with listItems that are new or have been updated ("toAddOrUpdate") and items marked for removal ("toRemove")
    */
    static func toSyncListItems(dbListItems: [ListItem]) -> (toAddOrUpdate: [ListItem], toRemove: [ListItem]) {
        // TODO send only items that are new or updated, currently sending everything
        // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
        var listItems: [ListItem] = []
        var toRemove: [ListItem] = []
        for listItem in dbListItems {
            if listItem.removed {
                toRemove.append(listItem)
            } else {
                // Send only "dirty" items
                // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
                // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
                // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
                // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
                if listItem.lastUpdate != listItem.lastServerUpdate {
                    listItems.append(listItem)
                }
            }
        }
        
        return (toAddOrUpdate: listItems, toRemove: toRemove)
    }
    
    /**
    Separates lists that are marked for removal from the rest
    And collects lists from "rest" which are new or have been updated
    
    :returns: tuple with lists that are new or have been updated ("toAddOrUpdate") and lists marked for removal ("toRemove")
    */
    static func toSyncLists(dbLists: [List]) -> (toAddOrUpdate: [List], toRemove: [List]) {
        // TODO send only items that are new or updated, currently sending everything
        // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
        var listItems: [List] = []
        var toRemove: [List] = []
        for listItem in dbLists {
            if listItem.removed {
                toRemove.append(listItem)
            } else {
                // Send only "dirty" items
                // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
                // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
                // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
                // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
                if listItem.lastUpdate != listItem.lastServerUpdate {
                    listItems.append(listItem)
                }
            }
        }
        
        return (toAddOrUpdate: listItems, toRemove: toRemove)
    }
 
    /// Create full sync object with lists and listItems
    static func toListsSync(dbLists: [List], dbListItems: [ListItem]) -> ListsSync {
        
        let (lists, toRemove) = self.toSyncLists(dbLists)
        
        // Group by list. Note we do this in tuples and using list in outer loop to preserve the order of the lists
        //                var listsItemsSyncs = [ListItemsSync]()
        var listsSyncs = [ListSync]()
        for dbList in lists { // we iterate through lists, not dbLists, because lists doesn't contain the lists marked for removal (it doesn't make sense to sync listitems for these lists)
            var listListItems = [ListItem]()
            for dbListItem in dbListItems {
                if dbListItem.list == dbList {
                    listListItems.append(dbListItem)
                    //                            dbListItems.removeAtIndex(i) // TODO remove the elements as we find them, to improve performance
                }
            }
            
            let (toAddOrUpdate, toRemove) = SyncUtils.toSyncListItems(listListItems)
            let listItemsSync = ListItemsSync(listItems: toAddOrUpdate, toRemove: toRemove)
            listsSyncs.append(ListSync(list: dbList, listItemsSync: listItemsSync))
        }
        
        return ListsSync(listsSyncs: listsSyncs, toRemove: toRemove)
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // Same code again for inventories.... (copied from lists - letting local vars names unchanged)
    
    /**
    Separates listItems that are marked for removal from the rest
    And collects listItems from "rest" which are new or have been updated
    
    :returns: tuple with listItems that are new or have been updated ("toAddOrUpdate") and items marked for removal ("toRemove")
    */
    static func toSyncInventoryItems(dbInventoryItems: [InventoryItem]) -> (toAddOrUpdate: [InventoryItem], toRemove: [InventoryItem]) {
        // TODO send only items that are new or updated, currently sending everything
        // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
        var listItems: [InventoryItem] = []
        var toRemove: [InventoryItem] = []
        for listItem in dbInventoryItems {
            if listItem.removed {
                toRemove.append(listItem)
            } else {
                // Send only "dirty" items
                // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
                // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
                // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
                // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
                if listItem.lastUpdate != listItem.lastServerUpdate {
                    listItems.append(listItem)
                }
            }
        }
        
        return (toAddOrUpdate: listItems, toRemove: toRemove)
    }
    
    /**
    Separates lists that are marked for removal from the rest
    And collects lists from "rest" which are new or have been updated
    
    :returns: tuple with lists that are new or have been updated ("toAddOrUpdate") and lists marked for removal ("toRemove")
    */
    static func toSyncInventories(dbInventories: [Inventory]) -> (toAddOrUpdate: [Inventory], toRemove: [Inventory]) {
        // TODO send only items that are new or updated, currently sending everything
        // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
        var listItems: [Inventory] = []
        var toRemove: [Inventory] = []
        for listItem in dbInventories {
            if listItem.removed {
                toRemove.append(listItem)
            } else {
                // Send only "dirty" items
                // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
                // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
                // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
                // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
                if listItem.lastUpdate != listItem.lastServerUpdate {
                    listItems.append(listItem)
                }
            }
        }
        
        return (toAddOrUpdate: listItems, toRemove: toRemove)
    }
    
    /// Create full sync object with lists and listItems
    static func toInventoriesSync(dbInventories: [Inventory], dbInventoryItems: [InventoryItem]) -> InventoriesSync {
        
        let (lists, toRemove) = self.toSyncInventories(dbInventories)
        
        // Group by list. Note we do this in tuples and using list in outer loop to preserve the order of the lists
        //                var listsItemsSyncs = [ListItemsSync]()
        var listsSyncs = [InventorySync]()
        for dbList in lists { // we iterate through lists, not dbLists, because lists doesn't contain the lists marked for removal (it doesn't make sense to sync listitems for these lists)
            var listListItems = [InventoryItem]()
            for dbListItem in dbInventoryItems {
                if dbListItem.inventory == dbList {
                    listListItems.append(dbListItem)
                    //                            dbListItems.removeAtIndex(i) // TODO remove the elements as we find them, to improve performance
                }
            }
            
            let (toAddOrUpdate, toRemove) = SyncUtils.toSyncInventoryItems(listListItems)
            let listItemsSync = InventoryItemsSync(inventoryItems: toAddOrUpdate, toRemove: toRemove)
            listsSyncs.append(InventorySync(inventory: dbList, inventoryItemsSync: listItemsSync))
        }
        
        return InventoriesSync(inventoriesSyncs: listsSyncs, toRemove: toRemove)
    }
}
