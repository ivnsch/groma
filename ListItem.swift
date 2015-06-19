//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


final class ListItem: Equatable {
    let uuid: String
    var done: Bool
    let quantity: Int
    let product: Product
    var section: Section
    var list: List
   
    var order: Int
    
    init(uuid: String, done: Bool, quantity: Int, product: Product, section: Section, list: List, order: Int) {
        self.uuid = uuid
        self.done = done
        self.quantity = quantity
        self.product = product
        self.section = section
        self.list = list
        self.order = order
    }
}

func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.uuid == rhs.uuid
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, lists
// so products, sections and lists arrays are the result of extracting the unique products, sections and list from listItems array
typealias ListItemsWithRelations = (listItems: [ListItem], products: [Product], sections: [Section], lists: [List])