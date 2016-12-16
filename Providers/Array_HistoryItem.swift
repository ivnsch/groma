//
//  Array_HistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 10/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array where Element: HistoryItem {

    public var totalQuantity: Int {
        return reduce(0) {sum, element in sum + element.quantity}
    }

    public var totalPrice: Float {
        return reduce(0) {sum, element in sum + (Float(element.quantity) * element.paidPrice)}
    }
}
