//
//  RemoteBuyCartResult.swift
//  shoppin
//
//  Created by ischuetz on 22/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteBuyCartResult: ResponseObjectSerializable, CustomDebugStringConvertible {

    let switchedItems: [RemoteSwitchAllListItemResult]
    let inventoryAndHistoryItems: RemoteInventoryItemsWithHistoryAndDependencies
    
    init?(representation: AnyObject) {
        guard
            let itemsObj = representation.valueForKeyPath("listItems"),
            let items = RemoteSwitchAllListItemResult.collection(itemsObj),
            let inventoryAndHistoryItemsObj = representation.valueForKeyPath("inventoryAndHistoryItems"),
            let inventoryAndHistoryItems = RemoteInventoryItemsWithHistoryAndDependencies(representation: inventoryAndHistoryItemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.switchedItems = items
        self.inventoryAndHistoryItems = inventoryAndHistoryItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) items: \(switchedItems), inventoryAndHistoryItems: [\(inventoryAndHistoryItems)]}"
    }
}

