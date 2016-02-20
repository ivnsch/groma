//
//  RemoteListsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 07/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteListsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {

    let inventories: [RemoteInventory]
    let lists: [RemoteList]
    
    // TODO After porting to Swift 2.0 catch exception in these initializers and show msg to client accordingly, or don't use force unwrap
    // if server for some reason doesn't send a field the app currently crashes
    init?(representation: AnyObject) {
        let inventories = representation.valueForKeyPath("inventories")!
        self.inventories = RemoteInventory.collection(inventories)
        
        let lists: AnyObject = representation.valueForKeyPath("lists")!
        self.lists = RemoteList.collection(lists)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventories: \(inventories), lists: \(lists)}"
    }
}