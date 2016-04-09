//
//  RemoteSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import QorumLogs

struct RemoteSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let productCategories: [[String: AnyObject]]
    let products: [[String: AnyObject]]
    let storeProducts: [[String: AnyObject]]
    let inventories: [[String: AnyObject]]
    let inventoriesItems: [[String: AnyObject]]
    let lists: [[String: AnyObject]]
    let sections: [[String: AnyObject]]
    let listsItems: [[String: AnyObject]]
    let groups: [[String: AnyObject]]
    let groupsItems: [[String: AnyObject]]
    let history: [[String: AnyObject]]
    let listInvitations: [RemoteListInvitation]
    let inventoryInvitations: [RemoteInventoryInvitation]
    
    init?(representation: AnyObject) {
        guard
            let productCategories = representation.valueForKeyPath("productCategories") as? [[String: AnyObject]],
            let products = representation.valueForKeyPath("products") as? [[String: AnyObject]],
            let storeProducts = representation.valueForKeyPath("storeProducts") as? [[String: AnyObject]],
            let inventories = representation.valueForKeyPath("inventories") as? [[String: AnyObject]],
            let inventoriesItems = representation.valueForKeyPath("inventoriesItems") as? [[String: AnyObject]],
            let lists = representation.valueForKeyPath("lists") as? [[String: AnyObject]],
            let sections = representation.valueForKeyPath("sections") as? [[String: AnyObject]],
            let listsItems = representation.valueForKeyPath("listsItems") as? [[String: AnyObject]],
            let groups = representation.valueForKeyPath("groups") as? [[String: AnyObject]],
            let groupsItems = representation.valueForKeyPath("groupsItems") as? [[String: AnyObject]],
            let history = representation.valueForKeyPath("history") as? [[String: AnyObject]],
            let listInvitationsObj = representation.valueForKeyPath("listInvitations"),
            let listInvitations = RemoteListInvitation.collection(listInvitationsObj),
            let inventoryInvitationsObj = representation.valueForKeyPath("inventoryInvitations"),
            let inventoryInvitations = RemoteInventoryInvitation.collection(inventoryInvitationsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.productCategories = productCategories
        self.products = products
        self.storeProducts = storeProducts
        self.inventories = inventories
        self.inventoriesItems = inventoriesItems
        self.lists = lists
        self.sections = sections
        self.listsItems = listsItems
        self.groups = groups
        self.groupsItems = groupsItems
        self.history = history
        self.listInvitations = listInvitations
        self.inventoryInvitations = inventoryInvitations
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productCategories: \(productCategories), products: \(products), storeProducts: \(storeProducts), inventories: \(inventories), inventoryInvitations: \(inventoryInvitations)}"
    }
}