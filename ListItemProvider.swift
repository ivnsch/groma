//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListItemProvider {
    
    func products(handler: ProviderResult<[Product]> -> ())
    
    func sections(handler: ProviderResult<[Section]> -> ())

    func remove(listItem: ListItem, _ handler: ProviderResult<Any> -> ())
    
    func remove(section: Section, _ handler: ProviderResult<Any> -> ())
    
    func remove(list: List, _ handler: ProviderResult<Any> -> ())

    func add(listItem: ListItem, _ handler: ProviderResult<Any> -> ())

    /**
    Adds a new list item
    The corresponding product and section will be added if no one with given unique exists
    - parameter list: list where the list item is
    - parameter order:  position of listitem in section. If nil will be appended at the end TODO always pass
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. Not an optional for easy handling, just pass by default current sections count.
    - parameter handler
    */
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int?, possibleNewSectionOrder: Int, _ handler: ProviderResult<ListItem> -> ())
    
    func update(listItem: ListItem, _ handler: ProviderResult<Any> -> ())

    func update(listItems: [ListItem], _ handler: ProviderResult<Any> -> ())
        
    func lists(handler: ProviderResult<[List]> -> ())

    func list(listId: String, _ handler: ProviderResult<List> -> ())
    
    func listItems(list: List, fetchMode: ProviderFetchModus, _ handler: ProviderResult<[ListItem]> -> ())
    
    // TODO remove
    func updateDone(listItems:[ListItem], _ handler: ProviderResult<Any> -> ())
    
    /**
    Updates done status of listItems, and their "order" field such that they are positioned at the end of the new section.
    ** Note ** word SWITCH: done expected to be != all listItem.done. This operation is meant to be used to append the items at the end of the section corresponding to new "done" state
    so we must not use it against the same tableview/state where we already are, because the items will update "order" field incorrectly by basically being appended after themselves.
    TODO cleaner implementation, maybe split in smaller methods. The method should not lead to inconsistent result when used in wrong context (see explanation above)
    */
    func switchDone(listItems: [ListItem], list: List, done: Bool, _ handler: ProviderResult<Any> -> ())

    func syncListItems(list: List, handler: (ProviderResult<Any>) -> ())
}
