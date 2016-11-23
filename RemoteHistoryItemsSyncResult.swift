//
//  RemoteHistoryItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RemoteHistoryItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {

    let historyItems: RemoteHistoryItems
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    init(historyItems: RemoteHistoryItems, couldNotUpdate: [String], couldNotDelete: [String]) {
        self.historyItems = historyItems
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    init?(representation: AnyObject) {
        guard
            let historyItemsObj = representation.value(forKeyPath: "historyItems") as? [AnyObject],
            let historyItems = RemoteHistoryItems(representation: historyItemsObj as AnyObject),
            let couldNotUpdate = representation.value(forKeyPath: "couldNotUpdate") as? [String],
            let couldNotDelete = representation.value(forKeyPath: "couldNotDelete") as? [String]
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.historyItems = historyItems
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventoryItems: \(historyItems), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete)}"
    }
}
