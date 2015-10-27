//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListItemProvider {

    // TODO create ProductsProvider, put products methods there
    
    // MARK: - Product
    
    func product(name: String, handler: ProviderResult<Product> -> ())
    
    func products(handler: ProviderResult<[Product]> -> ())
    
    func add(product: Product, handler: ProviderResult<Any> -> ())
    
    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ())
    
    func loadProduct(name: String, handler: ProviderResult<Product> -> ())
    
    // MARK: - Section
    
    func sectionSuggestions(handler: ProviderResult<[Suggestion]> -> ())

    func sections(names: [String], handler: ProviderResult<[Section]> -> ())

    func remove(section: Section, _ handler: ProviderResult<Any> -> ())

    func loadSection(name: String, list: List, handler: ProviderResult<Section> -> ())

    // MARK: - List

    func lists(handler: ProviderResult<[List]> -> ())
    
    func list(listId: String, _ handler: ProviderResult<List> -> ())
    
    // MARK: - ListItem

    func remove(listItem: ListItem, _ handler: ProviderResult<Any> -> ())
    
    func remove(list: List, _ handler: ProviderResult<Any> -> ())

    func add(listItem: ListItem, _ handler: ProviderResult<ListItem> -> ())

    func add(listItems: [ListItem], _ handler: ProviderResult<[ListItem]> -> ())
    
    /**
    Adds a new list item
    The corresponding product and section will be added if no one with given unique exists
    - parameter list: list where the list item is
    - parameter order:  position of listitem in section. If nil will be appended at the end TODO always pass
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    - parameter handler
    */
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int?, possibleNewSectionOrder: Int?, _ handler: ProviderResult<ListItem> -> Void)
    
    func addListItem(product: Product, sectionName: String, quantity: Int, list: List, note: String?, order orderMaybe: Int?, _ handler: ProviderResult<ListItem> -> Void)
    
    func update(listItem: ListItem, _ handler: ProviderResult<Any> -> ())

    func update(listItems: [ListItem], _ handler: ProviderResult<Any> -> ())
    
    func listItems(list: List, fetchMode: ProviderFetchModus, _ handler: ProviderResult<[ListItem]> -> ())
    
    /**
    Updates done status of listItems, and their "order" field such that they are positioned at the end of the new section.
    ** Note ** word SWITCH: done expected to be != all listItem.done. This operation is meant to be used to append the items at the end of the section corresponding to new "done" state
    so we must not use it against the same tableview/state where we already are, because the items will update "order" field incorrectly by basically being appended after themselves.
    TODO cleaner implementation, maybe split in smaller methods. The method should not lead to inconsistent result when used in wrong context (see explanation above)
    */
    func switchStatus(listItems: [ListItem], list: List, status: ListItemStatus, _ handler: ProviderResult<Any> -> ())

    func syncListItems(list: List, handler: (ProviderResult<Any>) -> ())
    
    func invalidateMemCache()
    
    // MARK: - GroupItem / ListItem
    
    /**
    * Converts group items in list items and adds them to list
    */
    func add(groupItems: [GroupItem], list: List, _ handler: ProviderResult<[ListItem]> -> ())
    
    // MARK: -

    /**
    There are some utility methods to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load the product or section using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    */
    func mergeOrCreateProduct(productName: String, productPrice: Float, category: String, _ handler: ProviderResult<Product> -> Void)
    func mergeOrCreateSection(sectionName: String, possibleNewOrder: Int?, list: List, _ handler: ProviderResult<Section> -> Void)
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(status: ListItemStatus, list: List, _ handler: ProviderResult<Int> -> Void)
}
