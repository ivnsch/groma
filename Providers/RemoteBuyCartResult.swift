//
//  RemoteBuyCartResult.swift
//  shoppin
//
//  Created by ischuetz on 22/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteBuyCartResult: ResponseObjectSerializable, CustomDebugStringConvertible {

    public let switchedItems: [RemoteSwitchAllListItemResult]
    public let inventoryAndHistoryItems: RemoteInventoryItemsWithHistoryAndDependencies
    
    public init?(representation: AnyObject) {
        guard
            let itemsObj = representation.value(forKeyPath: "listItems") as? [AnyObject],
            let items = RemoteSwitchAllListItemResult.collection(itemsObj),
            let inventoryAndHistoryItemsObj = representation.value(forKeyPath: "inventoryAndHistoryItems"),
            let inventoryAndHistoryItems = RemoteInventoryItemsWithHistoryAndDependencies(representation: inventoryAndHistoryItemsObj as AnyObject)
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.switchedItems = items
        self.inventoryAndHistoryItems = inventoryAndHistoryItems
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) items: \(switchedItems), inventoryAndHistoryItems: [\(inventoryAndHistoryItems)]}"
    }
}

