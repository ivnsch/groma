//
//  RemoteHistoryItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteHistoryItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {

    let historyItems: RemoteHistoryItems
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    init(historyItems: RemoteHistoryItems, couldNotUpdate: [String], couldNotDelete: [String]) {
        self.historyItems = historyItems
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let historyItems = representation.valueForKeyPath("historyItems") as! [AnyObject]
        self.historyItems = RemoteHistoryItems(response: response, representation: historyItems)!
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryItems: \(self.historyItems), couldNotUpdate: \(self.couldNotUpdate), couldNotDelete: \(self.couldNotDelete)}"
    }
}
