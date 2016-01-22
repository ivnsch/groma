//
//  TableViewListItem.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class TableViewListItem: CustomDebugStringConvertible {
   
    let listItem: ListItem
    var swiped: Bool = false
    
    init(listItem: ListItem) {
        self.listItem = listItem
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) \(listItem)}"
    }
}