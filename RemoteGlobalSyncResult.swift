//
//  RemoteGlobalSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import QorumLogs

struct RemoteGlobalSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let lists: [RemoteListWithListItems]
    let inventories: [RemoteInventoryWithItems]
    let history: [RemoteHistoryItems]
    let groups: [RemoteGroupWithItems]

    init?(representation: AnyObject) {
        guard
            let listsObj = representation.value(forKeyPath: "lists") as? [AnyObject],
            let lists = RemoteListWithListItems.collection(listsObj),
            let inventoriesObj = representation.value(forKeyPath: "inventories") as? [AnyObject],
            let inventories = RemoteInventoryWithItems.collection(inventoriesObj),
            let historyObj = representation.value(forKeyPath: "history") as? [AnyObject],
            let history = RemoteHistoryItems.collection(historyObj),
            let groupsObj = representation.value(forKeyPath: "groups") as? [AnyObject],
            let groups = RemoteGroupWithItems.collection(groupsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.lists = lists
        self.inventories = inventories
        self.history = history
        self.groups = groups
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) lists: \(lists), inventories: \(inventories), history: \(history), groups: \(groups)}"
    }
}
