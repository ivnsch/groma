//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class ListItem: Equatable {
    let id:String // unique, for now we use core data objectId to initialise this
    var done:Bool
    let product:Product
    let section:Section
    
    init(id:String, done:Bool, product:Product, section:Section) {
        self.id = id
        self.done = done
        self.product = product
        self.section = section
    }
}

func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.id == rhs.id
}