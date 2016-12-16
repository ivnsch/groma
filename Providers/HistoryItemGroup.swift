//
//  HistoryItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class HistoryItemGroup: CustomDebugStringConvertible {

    public let date: Date
    public let user: DBSharedUser
    public var historyItems: [HistoryItem]

    public lazy var totalPrice: Float = {
        self.historyItems.reduce(0) {sum, e in sum + (Float(e.totalPaidPrice))}
    }()

    public init(date: Date, user: DBSharedUser, historyItems: [HistoryItem]) {
        self.date = date
        self.user = user
        self.historyItems = historyItems
    }
    
    public func copy(_ date: Date? = nil, user: DBSharedUser? = nil, historyItems: [HistoryItem]? = nil) -> HistoryItemGroup {
        return HistoryItemGroup(
            date: date ?? self.date,
            user: user ?? self.user,
            historyItems: historyItems ?? self.historyItems
        )
    }
    
    public var debugDescription: String {
        return "[date: \(date), user: \(user), historyItems: \(historyItems)]"
    }
}
