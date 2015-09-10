//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class ListItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    var done: Bool
    let quantity: Int
    let product: Product
    var section: Section
    var list: List
   
    var order: Int // relative to section
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    
    init(uuid: String, done: Bool, quantity: Int, product: Product, section: Section, list: List, order: Int, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.done = done
        self.quantity = quantity
        self.product = product
        self.section = section
        self.list = list
        self.order = order
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    func same(listItem: ListItem) -> Bool {
        return self.uuid == listItem.uuid
    }
    
    var debugDescription: String {
        return shortDebugDescription
        //        return longDebugDescription
    }
    
    private var shortDebugDescription: String {
        return "[\(product.name), \(done), \(order)]"
    }

    private var longDebugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), done: \(self.done), quantity: \(self.quantity), order: \(self.order), productUuid: \(self.product), sectionUuid: \(self.section), listUuid: \(self.list), lastUpdate: \(self.lastUpdate), lastServerUpdate: \(self.lastServerUpdate), removed: \(self.removed)}"
    }
}

// TODO implement equality correctly, also in other model classes. Now we have identifiable for this.
func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.uuid == rhs.uuid
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, list
// so products, sections arrays and list are the result of extracting the unique products, sections and list from listItems array
typealias ListItemsWithRelations = (listItems: [ListItem], products: [Product], sections: [Section])