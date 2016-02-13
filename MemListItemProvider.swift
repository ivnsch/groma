//
//  MemListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class MemListItemProvider {

    private var listItems: [List: [ListItem]]? = [List: [ListItem]]()
    
    let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(list: List) -> [ListItem]? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}

        return listItems![list]
    }
    
    // Adds or increments listitem. Note: in increment case this increments all the status fron listItem! (todo, done, stash)
    // returns nil only if memory cache is not enabled
    func addListItem(listItem: ListItem) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}

        return syncedRet(self) {
            // TODO more elegant way to write this?
            if self.listItems![listItem.list] == nil {
                self.listItems![listItem.list] = []
            }
            
            // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
            // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
            var addedListItem: ListItem
            
            if let existingListItem = self.listItems![listItem.list]?.findFirstWithProductNameAndBrand(listItem.product.name, brand: listItem.product.brand) {
                let updatedListItem = existingListItem.increment(listItem)
                self.listItems![listItem.list]?.update(updatedListItem)
                addedListItem = updatedListItem
                
            } else {
                self.listItems![listItem.list]?.append(listItem)
                addedListItem = listItem

            }
            
            return addedListItem
        }
    }

    func addOrUpdateListItem(prototype: ListItemPrototype, status: ListItemStatus, list: List, note: String? = nil) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        // TODO more elegant way to write this?
        if self.listItems?[list] == nil {
            self.listItems?[list] = []
        }
        
        // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
        // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
        if let existingListItem = self.listItems![list]!.findFirstWithProductNameAndBrand(prototype.product.name, brand: prototype.product.brand) {
            
            let updatedSection = existingListItem.section.copy(name: prototype.targetSectionName) // TODO!!!! I think this is related with the bug with unwanted section update? for now letting like this since it's same functionality as before
            
            // TODO don't we have to update product and list here also?
            
            let updatedListItem = existingListItem.copyIncrement(section: updatedSection, note: note, statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.quantity))
            
            QL1("Item exists, updated it: \(updatedListItem)")

            self.listItems?[list]?.update(updatedListItem)
            
            return updatedListItem
        } else {
            
            // see if there's already a section for the new list item in the list, if not create a new one
            let sectionName = prototype.targetSectionName
            let section = (self.listItems![list]!.findFirst{$0.section.name == sectionName})?.section ?? {
                let sectionCount = self.listItems![list]!.sectionCount(status)
                return Section(uuid: NSUUID().UUIDString, name: sectionName, order: ListItemStatusOrder(status: status, order: sectionCount))
            }()
            
            var listItemOrder = 0
            for existingListItem in self.listItems![list]! {
                if existingListItem.section.uuid == section.uuid && existingListItem.hasStatus(status) { // count list items in my section (e.g. "vegetables") and status (e.g. "todo") to determine my order
                    listItemOrder++
                }
            }
            
            // create the list item and save it
            let listItem = ListItem(uuid: NSUUID().UUIDString, product: prototype.product, section: section, list: list, note: note, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.quantity))
            
            QL1("Item didn't exist, created one: \(listItem)")
            
            self.listItems?[listItem.list]?.append(listItem)
            
            return listItem
        }
    }

    func addOrUpdateListItems(prototypes: [ListItemPrototype], status: ListItemStatus, list: List, note: String? = nil) -> [ListItem]? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        QL1("Called with prototypes: \(prototypes)")

        var addedListItems: [ListItem] = []
        for prototype in prototypes {
            if let addedListItem = addOrUpdateListItem(prototype, status: status, list: list, note: note) {
                addedListItems.append(addedListItem)
            } else {
                print("Error: MemListItemProvider.addOrUpdateListItem: Invalid state: addedListItem is nil. This should not happen as nil is only returned when mem provider is disabled.")
            }
        }
        
        QL1("List mem cache after update: \(listItems?[list])")

        return addedListItems
    }

    
    func addOrUpdateListItem(product: Product, sectionNameMaybe: String? = nil, status: ListItemStatus, quantity: Int, list: List, note: String? = nil) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        let prototype = ListItemPrototype(product: product, quantity: quantity, targetSectionName: sectionNameMaybe ?? product.category.name)
        return addOrUpdateListItem(prototype, status: status, list: list, note: note)
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
        guard listItems != nil else {return false}
        
        // TODO more elegant way to write this?
        if self.listItems![listItem.list] != nil {
            self.listItems![listItem.list]!.remove(listItem)
            return true
        } else {
            return false
        }
    }
    
    func updateListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        // TODO more elegant way to write this?
        if self.listItems![listItem.list] != nil {
            self.listItems![listItem.list]?.update(listItem)
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
        guard listItems != nil else {return nil}
        
        if let _ = self.listItems![list] {
            return self.listItems![list]!.filterStash().count
        } else {
            QL1("Info: MemListItemProvider.listItemCount: there are no listitems for list: \(list)")
            return 0
        }
    }
    
    func increment(listItem: ListItem, quantity: ListItemStatusQuantity) -> Bool {
        // increment only quantity - in mem cache we don't care about quantityDelta, this cache is only used by the UI, not to write objs to database or server
        let incremented = listItem.increment(quantity)
        return updateListItem(incremented)
    }
    
    // Sets list items to nil
    // With this access to memory cache will be disabled (guards - check for nil) until the next overwrite
    // If we didn't set to nil we would be able to e.g. add list items to a emptied memory cache in which case it will not match the database contents
    func invalidate() {
        guard enabled else {return}
        
        QL1("Info: MemListItemProvider.invalidate: Invalidated list items memory cache")
        
        listItems = nil
    }
}
