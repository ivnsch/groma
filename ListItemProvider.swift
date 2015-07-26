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

    // optional order - if nil will be appended at the end
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int?, _ handler: ProviderResult<ListItem> -> ())
    
    func update(listItem: ListItem, _ handler: ProviderResult<Any> -> ())

    func update(listItems: [ListItem], _ handler: ProviderResult<Any> -> ())
        
    func lists(handler: ProviderResult<[List]> -> ())

    func list(listId: String, _ handler: ProviderResult<List> -> ())
    
    func listItems(list: List, fetchMode: ProviderFetchModus, _ handler: ProviderResult<[ListItem]> -> ())
    
    func updateDone(listItems:[ListItem], _ handler: ProviderResult<Any> -> ())
}
