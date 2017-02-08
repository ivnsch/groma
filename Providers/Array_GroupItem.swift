//
//  Array_GroupItem.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array where Element: GroupItem {

    public func sortBy(_ sortBy: InventorySortBy) -> [Element] {
        switch sortBy {
        case .alphabetic:
            return self.sorted{
                if $0.0.product.product.item.name == $0.1.product.product.item.name {
                    return $0.0.quantity < $0.1.quantity
                } else {
                    return $0.0.product.product.item.name < $0.1.product.product.item.name
                }
            }
        case .count:
            return self.sorted{
                if $0.0.quantity == $0.1.quantity {
                    return $0.0.product.product.item.name < $0.1.product.product.item.name
                } else {
                    return $0.0.quantity < $0.1.quantity
                }
            }
        }
    }
}
