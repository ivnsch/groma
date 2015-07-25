//
//  ListInput.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListInput {
    let uuid: String
    let name: String
    let users: [SharedUserInput] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    init(uuid: String, name: String, users: [SharedUserInput] = []) {
        self.uuid = uuid
        self.name = name
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), users: \(self.users)}"
    }
}