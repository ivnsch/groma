//
//  HistoryItemsSync.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class HistoryItemsSync {
    public let historyItems: [HistoryItem]
    public let toRemove: [HistoryItem]
    
    public init(historyItems: [HistoryItem], toRemove: [HistoryItem]) {
        self.historyItems = historyItems
        self.toRemove = toRemove
    }
}
