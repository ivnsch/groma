//
//  TableViewListItem.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class TableViewListItem: CustomDebugStringConvertible, Identifiable {
   
    let listItem: ListItem
    var swiped: Bool
    
    init(listItem: ListItem, swiped: Bool = false) {
        self.listItem = listItem
        self.swiped = swiped
    }
    
    func same(_ rhs: TableViewListItem) -> Bool {
        return listItem.same(rhs.listItem)
    }
    
    func copy(_ listItem: ListItem? = nil, swiped: Bool? = nil) -> TableViewListItem {
        return TableViewListItem(
            listItem: listItem ?? self.listItem,
            swiped: swiped ?? self.swiped
        )
    }
    
    
    var debugDescription: String {
        return "{\(type(of: self)) \(listItem)}"
    }
}
