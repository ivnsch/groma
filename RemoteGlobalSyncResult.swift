//
//  RemoteGlobalSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteGlobalSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let lists: [RemoteListWithListItems]
    let inventories: [RemoteInventoryWithItems]
    let history: [RemoteHistoryItems]
    let groups: [RemoteGroupWithItems]

    @objc required init?(representation: AnyObject) {
        
        let lists = representation.valueForKeyPath("lists") as! [AnyObject]
        self.lists = RemoteListWithListItems.collection(lists)

        let inventories = representation.valueForKeyPath("inventories") as! [AnyObject]
        self.inventories = RemoteInventoryWithItems.collection(inventories)
        
        let history = representation.valueForKeyPath("history") as! [AnyObject]
        self.history = RemoteHistoryItems.collection(history)
        
        let groups = representation.valueForKeyPath("groups") as! [AnyObject]
        self.groups = RemoteGroupWithItems.collection(groups)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) lists: \(lists), inventories: \(inventories), history: \(history), groups: \(groups)}"
    }
}