//
//  Inventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

struct Inventory: Equatable {
    let uuid: String
    let name: String
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)

    init(uuid: String, name: String, users: [SharedUser] = []) {
        self.uuid = uuid
        self.name = name
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), users: \(self.users)}"
    }
}

func ==(lhs: Inventory, rhs: Inventory) -> Bool {
    return lhs.uuid == rhs.uuid
}