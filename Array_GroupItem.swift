//
//  Array_GroupItem.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: GroupItem {

    func sortBy(sortBy: InventorySortBy) -> [Element] {
        switch sortBy {
        case .Alphabetic:
            return self.sort{
                if $0.0.product.name == $0.1.product.name {
                    return $0.0.quantity < $0.1.quantity
                } else {
                    return $0.0.product.name < $0.1.product.name
                }
            }
        case .Count:
            return self.sort{
                if $0.0.quantity == $0.1.quantity {
                    return $0.0.product.name < $0.1.product.name
                } else {
                    return $0.0.quantity < $0.1.quantity
                }
            }
        }
    }
}
