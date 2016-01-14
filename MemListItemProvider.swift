//
//  MemListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class MemListItemProvider {

    private var listItems: [List: [ListItem]]? = [List: [ListItem]]()
    
    let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(list: List) -> [ListItem]? {
        guard enabled else {return nil}
        guard var listItems = listItems else {return nil}
        
        return listItems[list]
    }
    
    // Adds or increments listitem. Note: in increment case this increments all the status fron listItem! (todo, done, stash)
    // returns nil only if memory cache is not enabled
    func addListItem(listItem: ListItem) -> ListItem? {
        guard enabled else {return nil}
        guard var listItems = listItems else {return nil}
        
        return syncedRet(self) {
            // TODO more elegant way to write this?
            if listItems[listItem.list] == nil {
                listItems[listItem.list] = []
            }
            
            // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
            // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
            var addedListItem: ListItem
            
            if let existingListItem = listItems[listItem.list]?.findFirstWithProductName(listItem.product.name) {
                let updatedListItem = existingListItem.increment(listItem)
                listItems[listItem.list]?.update(updatedListItem)
                addedListItem = updatedListItem
                
            } else {
                listItems[listItem.list]?.append(listItem)
                addedListItem = listItem
            }
            
            return addedListItem
        }
    }

    func addOrUpdateListItem(product: Product, sectionNameMaybe: String? = nil, status: ListItemStatus, quantity: Int, list: List, note: String? = nil) -> ListItem? {
        guard enabled else {return nil}
        guard var listItems = listItems else {return nil}
        
        // TODO more elegant way to write this?
        if listItems[list] == nil {
            listItems[list] = []
        }
        
        // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
        // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
        if let existingListItem = listItems[list]!.findFirstWithProductName(product.name) {

            let updatedSection = existingListItem.section.copy(name: sectionNameMaybe)

            // TODO don't we have to update product and list here also?
            
            let updatedListItem = existingListItem.copyIncrement(section: updatedSection, note: note, statusQuantity: ListItemStatusQuantity(status: status, quantity: quantity))
            
            self.listItems?[list]?.update(updatedListItem)
            
            return updatedListItem
        } else {
            
            // see if there's already a section for the new list item in the list, if not create a new one
            let sectionName = sectionNameMaybe ?? product.category.name
            let section = (listItems[list]!.findFirst{$0.section.name == sectionName})?.section ?? {
                let sectionCount = listItems[list]!.sectionCount
                return Section(uuid: NSUUID().UUIDString, name: sectionName, order: sectionCount)
            }()
            
            var listItemOrder = 0
            for existingListItem in listItems[list]! {
                if existingListItem.section.uuid == section.uuid && existingListItem.hasStatus(status) { // count list items in my section (e.g. "vegetables") and status (e.g. "todo") to determine my order
                    listItemOrder++
                }
            }
            
            // create the list item and save it
            let listItem = ListItem(uuid: NSUUID().UUIDString, product: product, section: section, list: list, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: quantity))
            
            self.listItems?[listItem.list]?.append(listItem)
            return listItem
        }
    }
    
    // returns nil only if memory cache is not enabled
    func addListItems(listItems: [ListItem]) -> [ListItem]? {
        guard enabled else {return nil}
        guard self.listItems != nil else {return nil}
        
        var addedListItems: [ListItem] = []
        for listItem in listItems {
            let addedListItem = addListItem(listItem)! // force unwarp - addListItem returns nil only if memory cache is not enabled. We know here it's enabled.
            addedListItems.append(addedListItem)
        }
        return addedListItems
    }
    
    func removeListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        guard var listItems = listItems else {return false}
        
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
        guard var listItems = listItems else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] != nil {
            self.listItems?[listItem.list]?.update(listItem)
            return true
        } else {
            return false
        }
    }

    func updateListItems(listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        guard self.listItems != nil else {return false}
        
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
    
    func listItemCount(status: ListItemStatus, list: List) -> Int? {
        guard enabled else {return nil}
        guard var listItems = listItems else {return nil}
        
        if let listItems = listItems[list] {
            return listItems.filterStash().count
        } else {
            print("Info: MemListItemProvider.listItemCount: there are no listitems for list: \(list)")
            return 0
        }
    }
    
    // Sets list items to nil
    // With this access to memory cache will be disabled (guards - check for nil) until the next overwrite
    // If we didn't set to nil we would be able to e.g. add list items to a emptied memory cache in which case it will not match the database contents
    func invalidate() {
        guard enabled else {return}
        
        listItems = nil
    }
}
