//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListItemProvider {
    
    func products(handler: Try<[Product]> -> ())
    
    func sections(handler: Try<[Section]> -> ())

    func remove(listItem: ListItem, handler: Try<Bool> -> ())
    
    func remove(section: Section, handler: Try<Bool> -> ())
    
    func remove(list: List, handler: Try<Bool> -> ())

    func add(listItem: ListItem, handler: Try<ListItem> -> ())

    // optional order - if nil will be appended at the end
    func add(listItemInput: ListItemInput, list: List, order: Int?, handler: Try<ListItem> -> ())
    
    func update(listItem: ListItem, handler: Try<Bool> -> ())

    func update(listItems: [ListItem], handler: Try<Bool> -> ())
    
    func add(list: List, handler: Try<List> -> ())
    
    func lists(handler: Try<[List]> -> ())

    func list(listId: String, handler: Try<List> -> ())
    
    func listItems(list: List, handler: Try<[ListItem]> -> ())
    
    func updateDone(listItems:[ListItem], handler: Try<Bool> -> ())
}
