//
//  ListItemRow.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

enum ListItemColumnIdentifier:String {
    case ProductName = "name"
    case Quantity = "quantity"
    case Price = "price"
    case Edit = "edit"
}

// wrapper to retrieve data for tableview
struct ListItemRow {
    var listItem:ListItem
    
    init(_ listItem:ListItem) {
        self.listItem = listItem
    }
    
    func getColumnString(columnIdentifier: ListItemColumnIdentifier) -> String? {
        switch columnIdentifier {
        case .ProductName:
            return listItem.product.name
        case .Quantity:
            return String(listItem.quantity)
        case .Price:
            return listItem.product.price.toString(2)!
        default:
            return nil
        }
    }
}
