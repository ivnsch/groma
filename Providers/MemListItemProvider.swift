//
//  MemListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation


class MemListItemProvider {

    fileprivate var listItems: [String: [ListItem]]? = [String: [ListItem]]()
    
    let enabled: Bool
    
    var valid: Bool {
        return enabled && listItems != nil // listItems != nil is enough but we check for enabled anyway
    }
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(_ list: List) -> [ListItem]? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}

        return listItems![list.uuid]
    }
    
    // Adds or increments listitem. Note: in increment case this increments all the status fron listItem! (todo, done, stash)
    // returns nil only if memory cache is not enabled
    func addListItem(_ listItem: ListItem) -> ListItem? {
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
            
            if let existingListItem = self.listItems![listItem.list.uuid]?.findFirstWith(quantifiableProductUnique: listItem.product.product.unique) {
//            if let existingListItem = self.listItems![listItem.list.uuid]?.findFirstWithProductNameAndBrand(listItem.product.product.product.name, brand: listItem.product.product.product.brand) {
                let updatedListItem = existingListItem.increment(listItem)
                _ = self.listItems![listItem.list.uuid]?.update(updatedListItem)
                addedListItem = updatedListItem
                
            } else {
                self.listItems![listItem.list.uuid]?.append(listItem)
                addedListItem = listItem

            }
            
            return addedListItem
        }
    }

    func addOrUpdateListItem(_ prototype: (prototype: StoreListItemPrototype, section: Section), status: ListItemStatus, list: List, note: String? = nil) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        // TODO more elegant way to write this?
        if self.listItems?[list.uuid] == nil {
            self.listItems?[list.uuid] = []
        }
        
        // TODO optimise this, for each list item we are iterating through the whole list items list. We should put listitems in dictionary with uuid or product name, or something
        // add case when a listitem with same product name already exist becomes an update: use uuid of existing item, and increment quantity - and of course use the rest of fields of new list item
        if let existingListItem = listItems![list.uuid]!.findFirstWith(storeProductUnique: prototype.prototype.product.unique) {
            
            let updatedSection = existingListItem.section.copy(name: prototype.prototype.targetSectionName) // TODO!!!! I think this is related with the bug with unwanted section update? for now letting like this since it's same functionality as before
            
            // TODO don't we have to update product and list here also?
            
            let updatedListItem = existingListItem.copyIncrement(section: updatedSection, note: note, statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.prototype.quantity))
            
            logger.v("Item exists, updated it: \(updatedListItem)")

            _ = self.listItems?[list.uuid]?.update(updatedListItem)
            
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
                    listItemOrder += 1
                }
            }
            
            // create the list item and save it
            let listItem = ListItem(uuid: UUID().uuidString, product: prototype.prototype.product, section: prototype.section, list: list, note: note, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.prototype.quantity))
            
            logger.v("Item didn't exist, created one: \(listItem)")
            
            self.listItems?[listItem.list.uuid]?.append(listItem)
            
            return listItem
        }
    }

    func addOrUpdateListItems(_ prototypes: [(StoreListItemPrototype, Section)], status: ListItemStatus, list: List, note: String? = nil) -> [ListItem]? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        logger.v("Called with prototypes: \(prototypes)")

        var addedListItems: [ListItem] = []
        for prototype in prototypes {
            if let addedListItem = addOrUpdateListItem(prototype, status: status, list: list, note: note) {
                addedListItems.append(addedListItem)
            } else {
                print("Error: MemListItemProvider.addOrUpdateListItem: Invalid state: addedListItem is nil. This should not happen as nil is only returned when mem provider is disabled.")
            }
        }
        
        logger.v("List mem cache after update: \(String(describing: listItems?[list.uuid]))")

        return addedListItems
    }
    
    // returns nil only if memory cache is not enabled
    func addListItems(_ listItems: [ListItem]) -> [ListItem]? {
        guard enabled else {return nil}
        guard self.listItems != nil else {return nil}
        
        var addedListItems: [ListItem] = []
        for listItem in listItems {
            let addedListItem = addListItem(listItem)! // force unwarp - addListItem returns nil only if memory cache is not enabled. We know here it's enabled.
            addedListItems.append(addedListItem)
        }
        return addedListItems
    }
    
    func removeListItem(_ listItem: ListItem) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        // TODO more elegant way to write this?
        if self.listItems![listItem.list.uuid] != nil {
            _ = self.listItems![listItem.list.uuid]!.remove(listItem)
            return true
        } else {
            return false
        }
    }

    func removeListItem(_ listUuid: String, uuid: String) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        if let list = (self.listItems?.keys.filter{$0 == listUuid})?.first {
            // TODO more elegant way to write this?
            if self.listItems![list] != nil {
                _ = self.listItems![list]!.removeWithUuid(uuid)
                return true
            } else {
                return false
            }
        } else {
            logger.w("Didn't find list of list item to be removed: listUuid: \(listUuid), list item uuid: \(uuid)")
            return false
        }
    }
    
    func updateListItem(_ listItem: ListItem) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        // TODO more elegant way to write this?
        if self.listItems![listItem.list.uuid] != nil {
            _ = self.listItems![listItem.list.uuid]?.update(listItem)
            return true
        } else {
            return false
        }
    }

    func updateListItems(_ listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        guard self.listItems != nil else {return false}
        
        for listItem in listItems {
            if !updateListItem(listItem) {
                return false
            }
        }
        
        return true
    }
    
    func overwrite(_ listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        
        invalidate()
        
        self.listItems = listItems.groupByList()
        
        return true
    }
    
    func listItemCount(_ status: ListItemStatus, list: List) -> Int? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        if let _ = self.listItems![list.uuid] {
            return self.listItems![list.uuid]!.filterStatus(status).count
        } else {
            logger.v("Info: MemListItemProvider.listItemCount: there are no listitems for list: \(list)")
            return 0
        }
    }
    
    fileprivate func findListItem(_ uuid: String, list: List) -> ListItem? {
        return self.listItems?[list.uuid]?.findFirst({$0.uuid == uuid})
    }
    
    func increment(_ listItem: ListItem, quantity: ListItemStatusQuantity) -> ListItem? {
        guard enabled else {return nil}
        guard listItems != nil else {return nil}
        
        if let cachedListItem = findListItem(listItem.uuid, list: listItem.list) { // increment the stored item - the passed one is just to get the uuid
            // increment only quantity - in mem cache we don't care about quantityDelta, this cache is only used by the UI, not to write objs to database or server
            let incremented = cachedListItem.increment(quantity)
            
            if updateListItem(incremented) {
                return incremented
                
            } else {
                logger.w("Item not updated")
                return nil
            }
            
        } else {
            logger.w("Item not found")
            return nil
        }
    }
    
    // listUuid: this is only an optimisation, in case we have the list uuid we avoid iterating through all the lists. Passing list uuid or not doesn't affect the result.
    // Note that currently this optimisation doesn't matter since we clear the mem cache after we leave a list so we have only one list in mem cache at a time. But we let it just in case.
    func removeSection(_ uuid: String, listUuid listUuidMaybe: String?) -> Bool {
        guard enabled else {return false}
        guard listItems != nil else {return false}
        
        if let listUuid = listUuidMaybe {
            // TODO the dictionary accessing logic is a bit weird, improve
            if let listUuid = (listItems?.keys.filter{$0 == listUuid})?.first {
                if let listListItems = listItems?[listUuid] {
                    let updatedListItems = listListItems.removeAllWithCondition{$0.section.uuid == uuid}
                    listItems?[listUuid] = updatedListItems
                    
                } else {
                    logger.v("No list items for section: \(uuid) in list: \(listUuid)")
                    return false
                }
                
            } else {
                logger.w("Didn't find list: \(listUuid)")
                return false
            }
            
        } else {
            for (listUuid, listListItems) in listItems! {
                let updatedListItems = listListItems.removeAllWithCondition{$0.section.uuid == uuid}
                listItems?[listUuid] = updatedListItems
            }
        }
        
        return true
    }
    
    // Sets list items to nil
    // With this access to memory cache will be disabled (guards - check for nil) until the next overwrite
    // If we didn't set to nil we would be able to e.g. add list items to a emptied memory cache in which case it will not match the database contents
    func invalidate() {
        guard enabled else {return}
        
        logger.v("Info: MemListItemProvider.invalidate: Invalidated list items memory cache")
        
        listItems = nil
    }
}
