//
//  RealmInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmInventoryProvider: RealmProvider {
   
    let dbListItemProvider = RealmListItemProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    
    func loadInventories(handler: [Inventory] -> ()) {
        let mapper = {InventoryMapper.inventoryWithDB($0)}
        self.load(mapper, handler: handler)
    }

//    func saveInventories(inventories: [DBInventory], handler: Bool -> ()) {
//        self.saveObjs(inventories, update: true, handler: handler)
//    }
    
//    func syncInventories(inventories incomingInventories: [DBInventory], handler: Bool -> ()) {
//        // update my inventories such my newest items and updates are not lost
//        
//        self.loadInventories {myInventories in
//            self.dbSyncProvider.loadSyncDate("inventory") {lastSyncDateMaybe in
//                
//                self.remoteInventoryProvider.syncInventories(myInventories) {
//                    
//                }
//                
//            }
//            
//            
//            
//            
////            var myInventoriesDictionary: [String: Inventory] = [:]
////            for inventory in myInventories {
////                myInventoriesDictionary[inventory.uuid] = inventory
////            }
////            
////            let inventoriesToSave = incomingInventories.filter {incomingInventory in
////                if let myInventory = myInventoriesDictionary[incomingInventory.uuid] {
////                    if myInventory.lastUpdate.timeIntervalSince1970 > incomingInventory.lastUpdate.timeIntervalSince1970 { // hm....
////                        return true
////                    } else {
////                        return false
////                    }
////
////                } else { // if the inventory is not in the local db yet, we want to save it
////                    return true
////                }
////            }
////            
//            
//            self.saveInventories(inventoriesToSave, handler: handler)
//        }
//    }

    
    func loadInventory(handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.load(mapper, handler: handler)
    }

    func saveInventory(inventory: Inventory, handler: Bool -> ()) {
        let dbObj = InventoryMapper.dbWithInventory(inventory)
        self.saveObj(dbObj, update: true, handler: handler)
    }
    
    func saveInventoryItems(items: [InventoryItem], handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }
}
