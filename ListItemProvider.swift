//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


protocol ListItemProvider {
    
    func products() -> [Product]
    
    func listItems() -> [ListItem]
    
    func sections() -> [Section]

    func remove(listItem:ListItem) -> Bool
    
    func add(listItem:ListItem) -> Bool

}
