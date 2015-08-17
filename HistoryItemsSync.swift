//
//  HistoryItemsSync.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryItemsSync {
    let historyItems: [HistoryItem]
    let toRemove: [HistoryItem]
    
    init(historyItems: [HistoryItem], toRemove: [HistoryItem]) {
        self.historyItems = historyItems
        self.toRemove = toRemove
    }
}
