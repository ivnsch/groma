//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class ListItem: Equatable {
    
    var done:Bool
    let product:Product
    let section:Section
    
    init(done:Bool, product:Product, section:Section) {
        self.done = done
        self.product = product
        self.section = section
    }
}

func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.product == rhs.product
}