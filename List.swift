//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class List: Equatable {
    let uuid: String
    let name: String
    let listItems: [ListItem]
    
    init(uuid: String, name:String, listItems:[ListItem] = []) {
        self.uuid = uuid
        self.name = name
        self.listItems = listItems
    }
}

func ==(lhs: List, rhs: List) -> Bool {
    return lhs.uuid == rhs.uuid
}