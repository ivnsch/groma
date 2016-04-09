//
//  HistoryItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryItemGroup: CustomDebugStringConvertible {

    let date: NSDate
    let user: SharedUser
    var historyItems: [HistoryItem]

    lazy var totalPrice: Float = {
        self.historyItems.reduce(0) {sum, e in sum + (Float(e.totalPaidPrice))}
    }()

    init(date: NSDate, user: SharedUser, historyItems: [HistoryItem]) {
        self.date = date
        self.user = user
        self.historyItems = historyItems
    }
    
    func copy(date: NSDate? = nil, user: SharedUser? = nil, historyItems: [HistoryItem]? = nil) -> HistoryItemGroup {
        return HistoryItemGroup(
            date: date ?? self.date,
            user: user ?? self.user,
            historyItems: historyItems ?? self.historyItems
        )
    }
    
    var debugDescription: String {
        return "[date: \(date), user: \(user), historyItems: \(historyItems)]"
    }
}
