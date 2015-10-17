//
//  MemListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class MemListItemProvider {

    private var listItems = [List: [ListItem]]()
    
    private let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(list: List) -> [ListItem]? {
        guard enabled else {return nil}
        
        return listItems[list]
    }
    
    // returns nil only if memory cache is not enabled
    func addListItem(listItem: ListItem) -> ListItem? {
        guard enabled else {return nil}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] == nil {
            listItems[listItem.list] = []
        }
     
        // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
        // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
        var addedListItem: ListItem
        if let existingListItem = listItems[listItem.list]?.findFirstWithProductName(listItem.product.name) {
            let updatedListItem = listItem.copy(uuid: existingListItem.uuid, quantity: existingListItem.quantity + listItem.quantity)
            listItems[listItem.list]?.update(updatedListItem)
            addedListItem = updatedListItem
            
        } else {
            listItems[listItem.list]?.append(listItem)
            addedListItem = listItem
        }
        return addedListItem
    }

    // returns nil only if memory cache is not enabled
    func addListItems(listItems: [ListItem]) -> [ListItem]? {
        guard enabled else {return nil}
        
        var addedListItems: [ListItem] = []
        for listItem in listItems {
            let addedListItem = addListItem(listItem)! // force unwarp - addListItem returns nil only if memory cache is not enabled. We know here it's enabled.
            addedListItems.append(addedListItem)
        }
        return addedListItems
    }
    
    func removeListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] != nil {
            listItems[listItem.list]?.remove(listItem)
            return true
        } else {
            return false
        }
    }
    
    func updateListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] != nil {
            listItems[listItem.list]?.update(listItem)
            return true
        } else {
            return false
        }
    }

    func updateListItems(listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        
        for listItem in listItems {
            if !updateListItem(listItem) {
                return false
            }
        }
        return true
    }
    
    func overwrite(listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        
        invalidate()
        
        self.listItems = listItems.groupByList()
        
        return true
    }
    
    func invalidate() {
        guard enabled else {return}
        
        listItems = [List: [ListItem]]()
    }
}
