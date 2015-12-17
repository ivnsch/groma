//
//  WSInventoryParser.swift
//  shoppin
//
//  Created by ischuetz on 09/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct WSInventoryParser {

    static func parseInventory(json: AnyObject) -> Inventory {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        let color = UIColor.purpleColor() // TODO
        let order = json.valueForKeyPath("order") as! Int
        return Inventory(uuid: uuid, name: name, bgColor: color, order: order)
    }

    static func parseInventoryItemIncrement(json: AnyObject) -> InventoryItemIncrement {
        let delta = json.valueForKeyPath("delta") as! Int
        let productUuid = json.valueForKeyPath("productUuid") as! String
        let inventoryUuid = json.valueForKeyPath("inventoryUuid") as! String
        
        return InventoryItemIncrement(delta: delta, productUuid: productUuid, inventoryUuid: inventoryUuid)
    }

    static func parseInventoryItemsWithHistory(jsonArray: [AnyObject]) -> [InventoryItemWithHistoryEntry] {
        var items: [InventoryItemWithHistoryEntry] = []
        for json in jsonArray {
            items.append(parseInventoryItemWithHistory(json))
        }
        return items
    }
    
    static func parseInventoryItemWithHistory(json: AnyObject) -> InventoryItemWithHistoryEntry {
        let inventoryItemObj = json.valueForKeyPath("inventoryItem")!
        let inventoryItem = parseInventoryItem(inventoryItemObj)
        
        let historyItemUuid = json.valueForKeyPath("historyItemUuid") as! String
        let addedDate = NSDate(timeIntervalSince1970: json.valueForKeyPath("addedDate") as! Double)
        
        let userObj = json.valueForKeyPath("user")!
        let user = WSUserParser.parseSharedUser(userObj)

        return InventoryItemWithHistoryEntry(inventoryItem: inventoryItem, historyItemUuid: historyItemUuid, addedDate: addedDate, user: user)
    }
    
    static func parseInventoryItem(json: AnyObject) -> InventoryItem {
        let quantity = json.valueForKeyPath("uuid") as! Int
        
        let productObj = json.valueForKeyPath("productInput")!
        let product = ListItemParser.parseProduct(productObj)
        
        let inventoryObj = json.valueForKeyPath("inventoryInput")!
        let inventory = parseInventory(inventoryObj)
        
        return InventoryItem(quantity: quantity, quantityDelta: 0, product: product, inventory: inventory) // TODO review quantity delta, since it comes from server it can be assumed it's 0 - right?
    }
    
    static func parseInventoryItemId(json: AnyObject) -> InventoryItemId {
        let inventoryUuid = json.valueForKeyPath("inventoryUuid") as! String
        let productUuid = json.valueForKeyPath("productUuid") as! String
        return InventoryItemId(inventoryUuid: inventoryUuid, productUuid: productUuid)
    }
    
    static func parseInventoryItems(jsonArray: [AnyObject]) -> [InventoryItem] {
        var items: [InventoryItem] = []
        for json in jsonArray {
            items.append(parseInventoryItem(json))
        }
        return items
    }
}
