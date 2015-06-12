//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


protocol ListItemProvider {
    
    func products(handler: Try<Product>)
    
    func sections() -> [Section]

    func remove(listItem:ListItem) -> Bool
    
    func remove(section:Section) -> Bool
    
    func remove(list:List) -> Bool

    func add(listItem:ListItem) -> ListItem?

    // optional order - if nil will be appended at the end
    func add(listItemInput:ListItemInput, list:List, order:Int?) -> ListItem?
    
    func update(listItem:ListItem) -> Bool

    func update(listItems:[ListItem]) -> Bool
    
    func add(list:List) -> List?
    
    func lists() -> [List]

    func list(listId:String) -> List?
    
    func listItems(list:List) -> [ListItem]
    
    func updateDone(listItems:[ListItem]) -> Bool
    
    var firstList:List {get}
}
