//
//  ListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemGroup: Identifiable, Equatable {

    let uuid: String
    let name: String
    var items: [GroupItem]
    let bgColor: UIColor

    init(uuid: String, name: String, items: [GroupItem] = [], bgColor: UIColor) {
        self.uuid = uuid
        self.name = name
        self.items = items
        self.bgColor = bgColor
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, items: [GroupItem]? = nil, bgColor: UIColor? = nil) -> ListItemGroup {
        return ListItemGroup(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            items: items ?? self.items,
            bgColor: bgColor ?? self.bgColor
        )
    }
    
    func same(rhs: ListItemGroup) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: ListItemGroup, rhs: ListItemGroup) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.name == rhs.name && lhs.items == rhs.items && lhs.bgColor == rhs.bgColor
}

extension ListItemGroup {
    
    var totalPrice: Float {
        return items.reduce(0.0) {sum, item in
            sum + item.product.price
        }
    }

    var totalQuantity: Int {
        return items.reduce(0) {sum, item in
            sum + item.quantity
        }
    }
}