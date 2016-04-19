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

    private var listItems: [String: [ListItem]]? = [String: [ListItem]]()
    
    let enabled: Bool
    
    var valid: Bool {
        return enabled && listItems != nil // listItems != nil is enough but we check for enabled anyway
    }
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(list: List) -> [ListItem]? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}

        return listItems![list.uuid]
    }
    
    // Adds or increments listitem. Note: in increment case this increments all the status fron listItem! (todo, done, stash)
    // returns nil only if memory cache is not enabled
    func addListItem(listItem: ListItem) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}

        return syncedRet(self) {
            // TODO more elegant way to write this?
            if self.listItems![listItem.list.uuid] == nil {
                self.listItems![listItem.list.uuid] = []
            }
            
            // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
            // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
            var addedListItem: ListItem
            
            if let existingListItem = self.listItems![listItem.list.uuid]?.findFirstWithProductNameAndBrand(listItem.product.product.name, brand: listItem.product.product.brand) {
                let updatedListItem = existingListItem.increment(listItem)
                self.listItems![listItem.list.uuid]?.update(updatedListItem)
                addedListItem = updatedListItem
                
            } else {
                self.listItems![listItem.list.uuid]?.append(listItem)
                addedListItem = listItem

            }
            
            return addedListItem
        }
    }

    func addOrUpdateListItem(prototype: (prototype: StoreListItemPrototype, section: Section), status: ListItemStatus, list: List, note: String? = nil) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        // TODO more elegant way to write this?
        if self.listItems?[list.uuid] == nil {
            self.listItems?[list.uuid] = []
        }
        
        // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
        // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
        if let existingListItem = self.listItems![list.uuid]!.findFirstWithProductNameAndBrand(prototype.prototype.product.product.name, brand: prototype.prototype.product.product.brand) {
            
            let updatedSection = existingListItem.section.copy(name: prototype.prototype.targetSectionName) // TODO!!!! I think this is related with the bug with unwanted section update? for now letting like this since it's same functionality as before
            
            // TODO don't we have to update product and list here also?
            
            let updatedListItem = existingListItem.copyIncrement(section: updatedSection, note: note, statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.prototype.quantity))
            
            QL1("Item exists, updated it: \(updatedListItem)")

            self.listItems?[list.uuid]?.update(updatedListItem)
            
            return updatedListItem
        } else {
            
            // if the section doesn't exist in the status where we are adding the list item, update its order field in this status to be the last one.
            if !self.listItems![list.uuid]!.hasSection(status, section: prototype.section) {
                let sectionCount = self.listItems![list.uuid]!.sectionCount(status)
                prototype.section.updateOrderMutable(ListItemStatusOrder(status: status, order: sectionCount))
            }

            var listItemOrder = 0
            for existingListItem in self.listItems![list.uuid]! {
                if existingListItem.section.uuid == prototype.section.uuid && existingListItem.hasStatus(status) { // count list items in my section (e.g. "vegetables") and status (e.g. "todo") to determine my order
                    listItemOrder++
                }
            }
            
            // create the list item and save it
            let listItem = ListItem(uuid: NSUUID().UUIDString, product: prototype.prototype.product, section: prototype.section, list: list, note: note, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.prototype.quantity))
            
            QL1("Item didn't exist, created one: \(listItem)")
            
            self.listItems?[listItem.list.uuid]?.append(listItem)
            
            return listItem
        }
    }

    func addOrUpdateListItems(prototypes: [(StoreListItemPrototype, Section)], status: ListItemStatus, list: List, note: String? = nil) -> [ListItem]? {
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
        
        QL1("List mem cache after update: \(listItems?[list.uuid])")

        return addedListItems
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
        if self.listItems![listItem.list.uuid] != nil {
            self.listItems![listItem.list.uuid]!.remove(listItem)
            return true
        } else {
            return false
        }
    }

    func removeListItem(listUuid: String, uuid: String) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        if let list = (self.listItems?.keys.filter{$0 == listUuid})?.first {
            // TODO more elegant way to write this?
            if self.listItems![list] != nil {
                self.listItems![list]!.removeWithUuid(uuid)
                return true
            } else {
                return false
            }
        } else {
            QL3("Didn't find list of list item to be removed: listUuid: \(listUuid), list item uuid: \(uuid)")
            return false
        }
    }
    
    func updateListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        // TODO more elegant way to write this?
        if self.listItems![listItem.list.uuid] != nil {
            self.listItems![listItem.list.uuid]?.update(listItem)
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
        
        if let _ = self.listItems![list.uuid] {
            return self.listItems![list.uuid]!.filterStash().count
        } else {
            QL1("Info: MemListItemProvider.listItemCount: there are no listitems for list: \(list)")
            return 0
        }
    }
    
    private func findListItem(uuid: String, list: List) -> ListItem? {
        return self.listItems?[list.uuid]?.findFirst({$0.uuid == uuid})
    }
    
    func increment(listItem: ListItem, quantity: ListItemStatusQuantity) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        if let cachedListItem = findListItem(listItem.uuid, list: listItem.list) { // increment the stored item - the passed one is just to get the uuid
            // increment only quantity - in mem cache we don't care about quantityDelta, this cache is only used by the UI, not to write objs to database or server
            let incremented = cachedListItem.increment(quantity)
            
            if updateListItem(incremented) {
                return incremented
                
            } else {
                QL3("Item not updated")
                return nil
            }
            
        } else {
            QL3("Item not found")
            return nil
        }
    }
    
    func removeSection(uuid: String, listUuid: String) -> Bool {
        guard enabled else {return false}
        
        // TODO the dictionary accessing logic is a bit weird, improve
        if let list = (listItems?.keys.filter{$0 == listUuid})?.first {
            if let listListItems = listItems?[list] {
                let updatedListItems = listListItems.removeAllWithCondition{$0.section.uuid == uuid}
                listItems?[list] = updatedListItems
                
            } else {
                QL1("No list items for section: \(uuid) in list: \(list)")
            }
            
        } else {
            QL3("Didn't find list: \(listUuid)")
            return false
        }
        
        return true
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
