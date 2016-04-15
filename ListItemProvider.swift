//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

enum SwitchListItemMode {case Single, All}

protocol ListItemProvider {
  
    func remove(listItem: ListItem, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func removeListItem(listItemUuid: String, listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ())

//    func add(listItem: ListItem, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<ListItem> -> ())

//    func add(listItems: [ListItem], status: ListItemStatus, remote: Bool, _ handler: ProviderResult<[ListItem]> -> ())
    
    /**
    Adds a new list item
    The corresponding product and section will be added if no one with given unique exists
    - parameter list: list where the list item is
    - parameter order:  position of listitem in section. If nil will be appended at the end TODO always pass
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    - parameter handler
    */
    func add(listItemInput: ListItemInput, status: ListItemStatus, list: List, order orderMaybe: Int?, possibleNewSectionOrder: ListItemStatusOrder?, _ handler: ProviderResult<ListItem> -> Void)
    
    // product/section same logic as add(listItemInput) (see doc above). TODO review other update methods maybe these should be removed or at least made private, since they don't have this product/section logic and there's no reason from outside of the provider to use a different logic (which would be to update the linked product/section directly).
    func update(listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, _ remote: Bool, _ handler: ProviderResult<ListItem> -> Void)
    
    func addListItem(product: Product, status: ListItemStatus, sectionName: String, sectionColor: UIColor, quantity: Int, list: List, note: String?, order orderMaybe: Int?, _ handler: ProviderResult<ListItem> -> Void)
    
    func add(prototypes: [ListItemPrototype], status: ListItemStatus, list: List, note: String?, order orderMaybe: Int?, _ handler: ProviderResult<[ListItem]> -> Void)

    func update(listItem: ListItem, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func update(listItems: [ListItem], remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func updateListItemsOrder(listItems: [ListItem], status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    // The counterpart of updateListItemsTodoOrder to process the update when it comes via websocket. We need a special service because websockets sends us a reduced payload (only the order and sections).
    func updateListItemsTodoOrderRemote(orderUpdates: [RemoteListItemReorder], sections: [Section], _ handler: ProviderResult<Any> -> Void)
    
    func listItems(list: List, sortOrderByStatus: ListItemStatus, fetchMode: ProviderFetchModus, _ handler: ProviderResult<[ListItem]> -> ())

    // This is currently used only to retrieve possible product's list item on receiving a websocket notification with a product update
    func listItem(product: Product, list: List, _ handler: ProviderResult<ListItem?> -> ())
    
    func increment(listItem: ListItem, delta: Int, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func increment(increment: ItemIncrement, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    /**
    Updates done status of listItems, and their "order" field such that they are positioned at the end of the new section.
    ** Note ** word SWITCH: done expected to be != all listItem.done. This operation is meant to be used to append the items at the end of the section corresponding to new "done" state
    so we must not use it against the same tableview/state where we already are, because the items will update "order" field incorrectly by basically being appended after themselves.
    TODO cleaner implementation, maybe split in smaller methods. The method should not lead to inconsistent result when used in wrong context (see explanation above)
    */
    func switchStatus(listItem: ListItem, list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func switchAllToStatus(listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func invalidateMemCache()
    
    // MARK: - GroupItem / ListItem
    
    /**
    * Converts group items in list items and adds them to list
    */
    func add(groupItems: [GroupItem], status: ListItemStatus, list: List, _ handler: ProviderResult<[ListItem]> -> ())

    func addGroupItems(group: ListItemGroup, status: ListItemStatus, list: List, _ handler: ProviderResult<[ListItem]> -> ())
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(status: ListItemStatus, list: List, fetchMode: ProviderFetchModus, _ handler: ProviderResult<Int> -> Void)
}
