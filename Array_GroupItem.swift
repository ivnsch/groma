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
            return self.sort{$0.0.product.name < $0.1.product.name}
        case .Count:
            return self.sort{$0.0.quantity < $0.1.quantity}
        }
    }
}
