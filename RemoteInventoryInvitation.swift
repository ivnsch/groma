//
//  RemoteInventoryInvitation.swift
//  shoppin
//
//  Created by ischuetz on 25/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryInvitation: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let sender: String // TODO send shared user obj not simply email
    let inventory: RemoteInventory
    
    init?(representation: AnyObject) {
        guard
            let sender = representation.valueForKeyPath("sender") as? String,
            let itemObj = representation.valueForKeyPath("item"),
            let inventory = RemoteInventory(representation: itemObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.sender = sender
        self.inventory = inventory
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryInvitation]? {
        var lists = [RemoteInventoryInvitation]()
        for obj in representation as! [AnyObject] {
            if let list = RemoteInventoryInvitation(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) sender: \(sender), inventory: \(inventory)}"
    }
}
