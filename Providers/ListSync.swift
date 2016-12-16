//
//  ListSync.swift
//  shoppin
//
//  Created by ischuetz on 07/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class ListSync {
    let list: List
    let listItemsSync: ListItemsSync
    
    public init(list: List, listItemsSync: ListItemsSync) {
        self.list = list
        self.listItemsSync = listItemsSync
    }
}

public class ListsSync {
    
    let listsSyncs: [ListSync]
    let toRemove: [List]
    
    public init(listsSyncs: [ListSync], toRemove: [List]) {
        self.listsSyncs = listsSyncs
        self.toRemove = toRemove
    }
}

public class ListItemsSync {
    let listItems: [ListItem]
    let toRemove: [ListItem]
    
    public init(listItems: [ListItem], toRemove: [ListItem]) {
        self.listItems = listItems
        self.toRemove = toRemove
    }
}
