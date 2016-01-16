//
//  TableViewListItem.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class TableViewListItem {
   
    let listItem: ListItem
    var swiped: Bool = false
    
    init(listItem: ListItem) {
        self.listItem = listItem
    }
}