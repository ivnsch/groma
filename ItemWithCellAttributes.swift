//
//  ItemWithCellAttributes.swift
//  shoppin
//
//  Created by ischuetz on 06/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// Model object with optional attributes, for now a range that has to be marked as bold. It depends on the concrete item T or use case where this range is applied.
struct ItemWithCellAttributes<T: Equatable>: Equatable {
    let item: T
    let boldRange: NSRange?
    init (item: T, boldRange: NSRange?) {
        self.item = item
        self.boldRange = boldRange
    }
    
    static func toItemWithCellAttributes(_ item: T) -> ItemWithCellAttributes<T> {
        return ItemWithCellAttributes<T>(item: item, boldRange: nil)
    }
    
    
    static func toItemsWithCellAttributes(_ items: [T]) -> [ItemWithCellAttributes<T>] {
        return items.map{toItemWithCellAttributes($0)}
    }
    
}
func ==<T>(lhs: ItemWithCellAttributes<T>, rhs: ItemWithCellAttributes<T>) -> Bool {
    return lhs.item == rhs.item
}
