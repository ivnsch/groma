//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class List: Equatable {
    let uuid: String
    let name: String
    let listItems: [ListItem] // TODO is this used? we get the items everywhere from the provider not the list object
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    init(uuid: String, name: String, listItems:[ListItem] = [], users: [SharedUser] = []) {
        self.uuid = uuid
        self.name = name
        self.listItems = listItems
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name)}"
    }
}

func ==(lhs: List, rhs: List) -> Bool {
    return lhs.uuid == rhs.uuid
}