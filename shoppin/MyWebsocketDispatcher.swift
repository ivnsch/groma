//
//  MyWebsocketDispatcher.swift
//  shoppin
//
//  Created by ischuetz on 09/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs


enum WSNotificationName: String {
    case ListItems = "WSListItems"
    case ListItem = "WSListItem"
    case List = "WSList"
    case Product = "WSProduct"
    case Group = "WSGroup"
    case GroupItem = "WSGroupItem"
    case Section = "WSSection"
    case Inventory = "WSInventory"
    case InventoryItems = "WSInventoryItems"
    case InventoryItem = "WSInventoryItem"
    case InventoryItemsWithHistory = "WSInventoryItemsWithHistory"
    case HistoryItem = "WSHistoryItem"
    case PlanItem = "WSPlanItem"
    
    // In some cases we need to receive the notification only after items have been persisted
    case InventoryItemsWithHistoryAfterSave = "WSInventoryItemsWithHistoryAfterSave"
}

enum WSNotificationVerb: String {
    case Add = "add"
    case Update = "update"
    case Delete = "delete"
}

final class WSNotification<T>: AnyObject {
    let verb: WSNotificationVerb
    let obj: T
    init (_ verb: WSNotificationVerb, _ obj: T) {
        self.verb = verb
        self.obj = obj
    }
}

final class WSEmptyNotification: AnyObject {
    let verb: WSNotificationVerb
    init (_ verb: WSNotificationVerb) {
        self.verb = verb
    }
}

let WSNotificationValue = "value"

struct MyWebsocketDispatcher {

    static func process(text: String) {
        
        if let data = (text as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                if let dict =  json as? Dictionary<String, AnyObject>  {
                    if let verb = dict["verb"] as? String, category = dict["category"] as? String, topic = dict["topic"] as? String, data = dict["message"] {
                        QL1("Websocket: Verb: \(verb), category: \(category), topic: \(topic), data: \(data)")
                        processCategory(category, verb: verb, topic: topic, data: data)
                    }
                }
                
            } catch let e as NSError { 
                QL4("Error: MyWebSocket.websocketDidReceiveMessage: deserializing json: \(e)")
            }
            
        } else {
            QL4("Error: MyWebSocket.websocketDidReceiveMessage: couldn't get data from text: \(text)")
        }
    }
    
    
    private static func processCategory(category: String, verb verbStr: String, topic: String, data: AnyObject) {
        guard let verb = WSNotificationVerb.init(rawValue: verbStr) else {QL4("Error: MyWebsocketDispatcher: Verb not supported: \(verbStr). Can't process. Category: \(category), topic: \(topic)"); return}
        
        switch category {
            case "product":
                processProduct(verb, topic, data)
            case "group":
                processGroup(verb, topic, data)
            case "groupItem":
                processGroupItem(verb, topic, data)
            case "planItem":
                processPlanItem(verb, topic, data)
            case "list":
                processList(verb, topic, data)
            case "listItem":
                processListItem(verb, topic, data)
            case "listItems":
                processListItems(verb, topic, data)
            case "section":
                processSection(verb, topic, data)
            case "inventory":
                processInventory(verb, topic, data)
            case "inventoryItem":
                processInventoryItem(verb, topic, data)
            case "inventoryItems":
                processInventoryItems(verb, topic, data)
            case "history":
                processHistoryItem(verb, topic, data)
        default:
            QL4("MyWebsocketDispatcher.processCategory not handled: \(category)")
        }
    }
    
    static func postNotification<T: Any>(notificationName: WSNotificationName, _ verb: WSNotificationVerb, _ obj: T) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSNotification(verb, obj)])
    }
    
    static func postNotification<T: Any>(notificationName: WSNotificationName, _ verb: WSNotificationVerb, _ obj: [T]) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSNotification(verb, obj)])
    }
    
    static func postEmptyNotification(notificationName: WSNotificationName, _ verb: WSNotificationVerb) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSEmptyNotification(verb)])
    }
    
    private static func processListItems(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
            case WSNotificationVerb.Update:
            let dataArr = data as! [AnyObject]
            let listItems = ListItemParser.parseArray(dataArr)
            postNotification(.ListItems, verb, listItems)
            
        default:
            QL4("MyWebsocketDispatcher.processListItems not handled: \(verb)")
        }
    }
    
    private static func processProduct(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
            case WSNotificationVerb.Add:
                let product = ListItemParser.parseProduct(data)
                postNotification(WSNotificationName.Product, verb, product)
            case WSNotificationVerb.Update:
                let product = ListItemParser.parseProduct(data)
                postNotification(.Product, verb, product)
            case WSNotificationVerb.Delete:
                let product = ListItemParser.parseProduct(data)
                postNotification(.Product, verb, product)
        }
    }
    
    private static func processGroup(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let group = WSGroupParser.parseGroup(data) // TODO review do we need group items here? if yes are they sent?
            postNotification(.Group, verb, group)
        case WSNotificationVerb.Update:
            let group = WSGroupParser.parseGroup(data)
            postNotification(.Group, verb, group)
        case WSNotificationVerb.Delete:
            let uuid = data as! String
            postNotification(.Group, verb, uuid)
        }
    }
    
    private static func processGroupItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
//        // for now not implemented as we don't add single group items, user always has to confirm on the group. Also, we don't have group here which is required by the provider
//        case WSNotificationVerb.Add:
//            let groupItemWithGroup = WSGroupParser.parseGroupItem(data)
//            postNotification(.GroupItem, verb, groupItemWithGroup)
        case WSNotificationVerb.Update:
            let groupItemWithGroup = WSGroupParser.parseGroupItem(data)
            postNotification(.GroupItem, verb, groupItemWithGroup)
        case WSNotificationVerb.Delete:
            let groupItemWithGroup = WSGroupParser.parseGroupItem(data)
            postNotification(.GroupItem, verb, groupItemWithGroup)
        default: QL4("MyWebsocketDispatcher.processGroupItem not handled: \(verb)")
        }
    }
    
    private static func processPlanItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let items = WSPlanItemParser.parsePlanItem(data) // TODO review do we need group items here? if yes are they sent?
            postNotification(.PlanItem, verb, items)
        case WSNotificationVerb.Update:
            let items = WSPlanItemParser.parsePlanItem(data)
            postNotification(.PlanItem, verb, items)
        case WSNotificationVerb.Delete:
            let items = WSPlanItemParser.parsePlanItem(data)
            postNotification(.PlanItem, verb, items)
        }
    }
    
    private static func processList(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let list = ListItemParser.parseList(data)
            postNotification(.List, verb, list)
        case WSNotificationVerb.Update:
            let list = ListItemParser.parseList(data)
            postNotification(.List, verb, list)
        case WSNotificationVerb.Delete:
            let listUuid = data as! String
            postNotification(.List, verb, listUuid)
        }
    }
    
    private static func processListItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let group = ListItemParser.parse(data)
            postNotification(.ListItem, verb, group)
        case WSNotificationVerb.Update:
            let group = ListItemParser.parse(data)
            postNotification(.ListItem, verb, group)
        case WSNotificationVerb.Delete:
            let group = ListItemParser.parse(data)
            postNotification(.ListItem, verb, group)
        }
    }
    
    private static func processSection(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let group = ListItemParser.parseSection(data)
            postNotification(.Section, verb, group)
        case WSNotificationVerb.Update:
            let group = ListItemParser.parseSection(data)
            postNotification(.Section, verb, group)
        case WSNotificationVerb.Delete:
            let group = ListItemParser.parseSection(data)
            postNotification(.Section, verb, group)
        }
    }
    
    private static func processInventory(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let inventory = WSInventoryParser.parseInventory(data)
            postNotification(.Inventory, verb, inventory)
        case WSNotificationVerb.Update:
            let inventory = WSInventoryParser.parseInventory(data)
            postNotification(.Inventory, verb, inventory)
        case WSNotificationVerb.Delete:
            let uuid = data as! String
            postNotification(.Inventory, verb, uuid)
        }
    }
    
    private static func processInventoryItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let dataArr = data as! [AnyObject]
            let group = WSInventoryParser.parseInventoryItemsWithHistory(dataArr)
            postNotification(.InventoryItemsWithHistory, verb, group)
        case WSNotificationVerb.Update:
            let group = WSInventoryParser.parseInventoryItem(data)
            postNotification(.InventoryItem, verb, group)
        case WSNotificationVerb.Delete:
            let group = WSInventoryParser.parseInventoryItemId(data)
            postNotification(.InventoryItem, verb, group)
        }
    }
    
    private static func processInventoryItems(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            let group = WSInventoryParser.parseInventoryItemIncrement(data)
            postNotification(.InventoryItems, verb, group)
            
        default: QL4("MyWebsocketDispatcher.processListItems not handled: \(verb)")
        }
    }
    
    
    private static func processHistoryItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Delete:
            let historyItemUuid = data
            postNotification(.HistoryItem, verb, historyItemUuid)
            
        default: QL4("MyWebsocketDispatcher.processListItems not handled: \(verb)")
        }
    }
}
