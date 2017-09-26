//
//  RemoteSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire


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
            let productCategories = representation.value(forKeyPath: "productCategories") as? [[String: AnyObject]],
            let products = representation.value(forKeyPath: "products") as? [[String: AnyObject]],
            let storeProducts = representation.value(forKeyPath: "storeProducts") as? [[String: AnyObject]],
            let inventories = representation.value(forKeyPath: "inventories") as? [[String: AnyObject]],
            let inventoriesItems = representation.value(forKeyPath: "inventoriesItems") as? [[String: AnyObject]],
            let lists = representation.value(forKeyPath: "lists") as? [[String: AnyObject]],
            let sections = representation.value(forKeyPath: "sections") as? [[String: AnyObject]],
            let listsItems = representation.value(forKeyPath: "listsItems") as? [[String: AnyObject]],
            let groups = representation.value(forKeyPath: "groups") as? [[String: AnyObject]],
            let groupsItems = representation.value(forKeyPath: "groupsItems") as? [[String: AnyObject]],
            let history = representation.value(forKeyPath: "history") as? [[String: AnyObject]],
            let listInvitationsObj = representation.value(forKeyPath: "listInvitations") as? [AnyObject],
            let listInvitations = RemoteListInvitation.collection(listInvitationsObj),
            let inventoryInvitationsObj = representation.value(forKeyPath: "inventoryInvitations") as? [AnyObject],
            let inventoryInvitations = RemoteInventoryInvitation.collection(inventoryInvitationsObj)
            else {
                logger.e("Invalid json: \(representation)")
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
        return "{\(type(of: self)) productCategories: \(productCategories), products: \(products), storeProducts: \(storeProducts), inventories: \(inventories), inventoryInvitations: \(inventoryInvitations)}"
    }
}
