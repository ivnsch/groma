//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class List: Equatable, Identifiable {
    let id:String // unique, for now we use core data objectId to initialise this
    let name:String
    let listItems:[ListItem]
    
    init(id:String, name:String, listItems:[ListItem] = []) {
        self.id = id
        self.name = name
        self.listItems = listItems
    }
}

func ==(lhs: List, rhs: List) -> Bool {
    return lhs.id == rhs.id
}