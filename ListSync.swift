//
//  ListSync.swift
//  shoppin
//
//  Created by ischuetz on 07/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListSync {
    let list: List
    let listItemsSync: ListItemsSync
    
    init(list: List, listItemsSync: ListItemsSync) {
        self.list = list
        self.listItemsSync = listItemsSync
    }
}

class ListsSync {
    
    let listsSyncs: [ListSync]
    let toRemove: [List]
    
    init(listsSyncs: [ListSync], toRemove: [List]) {
        self.listsSyncs = listsSyncs
        self.toRemove = toRemove
    }
}

class ListItemsSync {
    let listItems: [ListItem]
    let toRemove: [ListItem]
    
    init(listItems: [ListItem], toRemove: [ListItem]) {
        self.listItems = listItems
        self.toRemove = toRemove
    }
}