//
//  Array_Inventory.swift
//  shoppin
//
//  Created by ischuetz on 26/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: DBInventory {
    
    func sortedByOrder() -> [DBInventory] {
        return sorted {
            switch ($0.order, $1.order) {
            case let (lhs, rhs) where lhs == rhs: // this should normally not happen, but just in case, get a fixed ordering anyway
                return $0.name < $1.name
            case let (lhs, rhs):
                return lhs < rhs
            }
        }
    }
}
