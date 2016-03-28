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
    case ProductCategory = "WSProductCategory"
    case Group = "WSGroup"
    case Groups = "WSGroups"
    case GroupItem = "WSGroupItem"
    case Section = "WSSection"
    case Inventory = "WSInventory"
    case Inventories = "WSInventories"
    case InventoryItems = "WSInventoryItems"
    case InventoryItem = "WSInventoryItem"
    case InventoryItemsWithHistory = "WSInventoryItemsWithHistory"
    case HistoryItem = "WSHistoryItem"
    case PlanItem = "WSPlanItem"
    case SyncShared = "WSSyncShared"

    case Reception = "WSReception" // client generated
    case ProcessingError = "WSProcessingError" // client generated
    
    case Connection = "WSConnection"
    
    // In some cases we need to receive the notification only after items have been persisted
    case InventoryItemsWithHistoryAfterSave = "WSInventoryItemsWithHistoryAfterSave"
    
    // When a sync triggered by a websocket message (which is sent when another user or device did sync) is finished
    case IncomingGlobalSyncFinished = "WSIncomingGlobalSyncFinished"
}

enum WSNotificationVerb: String {
    case Add = "add"
    case Update = "update"
    case Delete = "delete"
    case Invite = "invite"
    case Sync = "sync"
    case Increment = "incr"
    case Fav = "fav"
    case Order = "order"
}

enum WSNotificationCategory: String {
    case Product = "product"
    case Category = "category"
    case Group = "group"
    case Groups = "groups"
    case GroupItem = "groupItem"
    case List = "list"
    case ListItem = "listItem"
    case ListItems = "listItems"
    case Section = "section"
    case Inventory = "inventory"
    case Inventories = "inventories"
    case InventoryItem = "inventoryItem"
    case InventoryItems = "inventoryItems"
    case History = "history"
    case Shared = "shared"
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
    
    static func processCategory(category: String, verb verbStr: String, topic: String, sender: String, data: AnyObject) {
        guard let verb = WSNotificationVerb.init(rawValue: verbStr) else {QL4("Error: MyWebsocketDispatcher: Verb not supported: \(verbStr). Can't process. Category: \(category), topic: \(topic), sender: \(sender)"); return}
        
        NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.Reception.rawValue, object: nil, userInfo: ["verb": verbStr, "category": category, "sender": sender])
        
        if let enumValue = WSNotificationCategory(rawValue: category) {
            switch enumValue {
            case .Product:
                processProduct(verb, topic, sender, data)
            case .Category:
                processProduct(verb, topic, sender, data)
            case .Group:
                processGroup(verb, topic, sender, data)
            case .Groups:
                processGroups(verb, topic, sender, data)
            case .GroupItem:
                processGroupItem(verb, topic, sender, data)
            case .List:
                processList(verb, topic, sender, data)
            case .ListItem:
                processListItem(verb, topic, sender, data)
            case .ListItems:
                processListItems(verb, topic, sender, data)
            case .Section:
                processSection(verb, topic, sender, data)
            case .Inventory:
                processInventory(verb, topic, sender, data)
            case .Inventories:
                processInventories(verb, topic, sender, data)
            case .InventoryItem:
                processInventoryItem(verb, topic, sender, data)
            case .InventoryItems:
                processInventoryItems(verb, topic, sender, data)
            case .History:
                processHistoryItem(verb, topic, sender, data)
            case .Shared:
                processShared(verb, topic, sender, data)
//            case "planItem":
//                processPlanItem(verb, topic, data)
            }
        } else {
            QL4("MyWebsocketDispatcher.processCategory not handled: \(category)")
        }
    }
    
    // Report errors when storing objects that came via websocket
    private static func reportWebsocketStoringError<T>(msg: String, result: ProviderResult<T>) {
        let report = ErrorReport(title: "Websocket storing", body: "msg: \(msg), result: \(result)")
        NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.ProcessingError.rawValue, object: nil, userInfo: nil)
        Providers.errorProvider.reportError(report)
        QL4("Websocket: Couldn't store: \(msg), result: \(result)")
    }

    private static func reportWebsocketParsingError(msg: String) {
        let report = ErrorReport(title: "Websocket parsing", body: "msg: \(msg)")
        NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.ProcessingError.rawValue, object: nil, userInfo: nil)
        Providers.errorProvider.reportError(report)
        QL4("Websocket: Couldn't parse: \(msg)")
    }
    
    private static func reportWebsocketGeneralError(msg: String) {
        let report = ErrorReport(title: "Websocket", body: "msg: \(msg)")
        NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.ProcessingError.rawValue, object: nil, userInfo: nil)
        Providers.errorProvider.reportError(report)
        QL4("Websocket General error: \(msg)")
    }
    
    static func postNotification<T: Any>(notificationName: WSNotificationName, _ verb: WSNotificationVerb, _ sender: String, _ obj: T) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSNotification(verb, obj)])
    }
    
    static func postNotification<T: Any>(notificationName: WSNotificationName, _ verb: WSNotificationVerb, _ sender: String, _ obj: [T]) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSNotification(verb, obj)])
    }
    
    static func postEmptyNotification(notificationName: WSNotificationName, _ verb: WSNotificationVerb) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName.rawValue, object: nil, userInfo: ["value": WSEmptyNotification(verb)])
    }
    
    
    //this is called on batch list item update, which is used when reordering list items
    private static func processListItems(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        // TODO!!!! test this
        case WSNotificationVerb.Order:
            if let remoteOrderUpdates = RemoteListItemsReorderResult(representation: data) {
                // NOTE: Assumption the update belongs to 1 list, that is, all the sections have the same list
                if let listUuid = remoteOrderUpdates.sections.first?.listUuid {
                    Providers.listProvider.list(listUuid) {listResult in
                        
                        if let list = listResult.sucessResult {
                            let sections = remoteOrderUpdates.sections.map{SectionMapper.SectionWithRemote($0, list: list)}
                            
                            Providers.listItemsProvider.updateListItemsTodoOrderRemote(remoteOrderUpdates.items, sections: sections) {updateResult in
                                if updateResult.success {
                                    postNotification(.ListItems, verb, sender, remoteOrderUpdates)
                                } else {
                                    MyWebsocketDispatcher.reportWebsocketStoringError("Update list items order \(remoteOrderUpdates)", result: updateResult)
                                }
                            }
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Update list items order \(remoteOrderUpdates)", result: listResult)
                        }
                    }
                } else {
                    QL4("Websocket warning/error: Received list items order update but the list was not found.") // Can happen if e.g. receiver just deleted the list. This must happen in a very short time, after the server did the order update. If we see this message frequently it's an error, as this is expected to happen rarely.
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update list items order, data: \(data)")
            }
        default:
            QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processProduct(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
            case .Add:
                if let remoteProducts = RemoteProductsWithDependencies(representation: data) {
                    if let product = ProductMapper.productsWithRemote(remoteProducts).products.first {
                        Providers.productProvider.add(product, remote: false) {result in
                            if result.success {
                                postNotification(.Product, verb, sender, product)
                            } else {
                                MyWebsocketDispatcher.reportWebsocketStoringError("Add \(product)", result: result)
                            }
                        }
                    } else {
                        reportWebsocketGeneralError("Add product didn't return a product")
                    }
                } else {
                    MyWebsocketDispatcher.reportWebsocketParsingError("Add product, data: \(data)")
                }

            case .Update:
                if let remoteProducts = RemoteProductsWithDependencies(representation: data) {
                    if let product = ProductMapper.productsWithRemote(remoteProducts).products.first {
                        Providers.productProvider.update(product, remote: false) {result in
                            if result.success {
                                postNotification(.Product, verb, sender, product)
                            } else {
                                MyWebsocketDispatcher.reportWebsocketStoringError("Update \(product)", result: result)
                            }
                        }
                    } else {
                        reportWebsocketGeneralError("Update product didn't return a product")
                    }
                } else {
                    MyWebsocketDispatcher.reportWebsocketParsingError("Update product, data: \(data)")
                }
                
            case .Delete:
                if let productUuid = data as? String {
                    Providers.productProvider.delete(productUuid, remote: false) {result in
                        if result.success {
                            postNotification(.Product, verb, sender, productUuid)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(productUuid)", result: result)
                        }
                    }
                } else {
                    MyWebsocketDispatcher.reportWebsocketParsingError("Delete product, data: \(data)")
                }

            case .Fav:
                if let productUuid = data as? String {
                    Providers.productProvider.incrementFav(productUuid, remote: false) {result in
                        if result.success {
                            postNotification(.Product, verb, sender, productUuid)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Increment product fav \(productUuid)", result: result)
                        }
                    }
                } else {
                    MyWebsocketDispatcher.reportWebsocketParsingError("Increment product fav, data: \(data)")
                }
            
            default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processProductCategory(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case .Update:
            if let remoteCategory = RemoteProductCategory(representation: data) {
                let category = ProductCategoryMapper.categoryWithRemote(remoteCategory)
                Providers.productCategoryProvider.update(category, remote: false) {result in
                    if result.success {
                        postNotification(.ProductCategory, verb, sender, category)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Update \(category)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update category, data: \(data)")
            }
            
        case .Delete:
            if let categoryUuid = data as? String {
                Providers.productCategoryProvider.remove(categoryUuid, remote: false) {result in
                    if result.success {
                        postNotification(.ProductCategory, verb, sender, categoryUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(categoryUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete category, data: \(data)")
            }

        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processGroup(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            if let remoteGroup = RemoteGroup(representation: data) {
                let group = ListItemGroupMapper.listItemGroupWithRemote(remoteGroup)
                Providers.listItemGroupsProvider.add(group, remote: false) {result in
                    if result.success {
                        postNotification(.Group, verb, sender, group)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Add \(group)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add Group, data: \(data)")
            }

        case WSNotificationVerb.Update:
            if let remoteGroup = RemoteGroup(representation: data) {
                let group = ListItemGroupMapper.listItemGroupWithRemote(remoteGroup)
                Providers.listItemGroupsProvider.update(group, remote: false) {result in
                    if result.success {
                        postNotification(.Group, verb, sender, group)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Update \(group)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update Group, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let groupUuid = data as? String {
                Providers.listItemGroupsProvider.removeGroup(groupUuid, remote: false) {result in
                    if result.success {
                        postNotification(.Group, verb, sender, groupUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(groupUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete Group, data: \(data)")
            }
            
        case .Fav:
            if let groupUuid = data as? String {
                Providers.listItemGroupsProvider.incrementFav(groupUuid, remote: false) {result in
                    if result.success {
                        postNotification(.Group, verb, sender, groupUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Increment group fav \(groupUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Increment group fav, data: \(data)")
            }

        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processGroups(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Order:
            if let remoteOrderUpdates = RemoteOrderUpdate.collection(data) {
                let orderUpdates = remoteOrderUpdates.map{OrderUpdate(uuid: $0.uuid, order: $0.order)}
                Providers.listItemGroupsProvider.updateGroupsOrder(orderUpdates, remote: false) {result in
                    if result.success {
                        postNotification(.Groups, verb, sender, remoteOrderUpdates)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Update groups order \(remoteOrderUpdates)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update groups order, data: \(data)")
            }
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processGroupItem(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
//        // for now not implemented as we don't add single group items, user always has to confirm on the group. Also, we don't have group here which is required by the provider
        case WSNotificationVerb.Add:
            if let remoteGroupItems = RemoteGroupItemsWithDependencies(representation: data) {
                if let groupItem = GroupItemMapper.groupItemsWithRemote(remoteGroupItems).groupItems.first {
                    Providers.listItemGroupsProvider.add(groupItem, remote: false) {result in
                        if result.success {
                            postNotification(.GroupItem, verb, sender, groupItem)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Add \(groupItem)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Add group item didn't return a group item")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add group item, data: \(data)")
            }

            
        case WSNotificationVerb.Update:
            if let remoteGroupItems = RemoteGroupItemsWithDependencies(representation: data) {
                if let groupItem = GroupItemMapper.groupItemsWithRemote(remoteGroupItems).groupItems.first {
                    Providers.listItemGroupsProvider.update(groupItem, remote: false) {result in
                        if result.success {
                            postNotification(.GroupItem, verb, sender, groupItem)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Update \(groupItem)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Add group item didn't return a group item")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add group item, data: \(data)")
            }

        case WSNotificationVerb.Increment:
            if let remoteIncrement = RemoteIncrement(representation: data) {
                let increment = ItemIncrement(delta: remoteIncrement.delta, itemUuid: remoteIncrement.uuid) // TODO!!!! pass the last update timestamp also?
                Providers.listItemGroupsProvider.increment(increment, remote: false) {result in
                    if result.success {
                        postNotification(.GroupItem, verb, sender, increment)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Increment group item \(remoteIncrement)", result: result)
                    }
                }
                
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update group item, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let groupItemUuid = data as? String {
                Providers.listItemGroupsProvider.removeGroupItem(groupItemUuid, remote: false) {result in
                    if result.success {
                        postNotification(.GroupItem, verb, sender, groupItemUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(groupItemUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete Group item, data: \(data)")
            }
            
        default: QL4("Not handled verb: \(verb)")
        }
    }

    private static func processList(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            if let remoteList = RemoteListsWithDependencies(representation: data) {
                if let list = ListMapper.listsWithRemote(remoteList).first {
                    Providers.listProvider.add(list, remote: false) {result in
                        if result.success {
                            postNotification(.List, verb, sender, list)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Add \(list)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Add list didn't return a list")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add list, data: \(data)")
            }
            
        case WSNotificationVerb.Update:
            if let remoteList = RemoteListsWithDependencies(representation: data) {
                if let list = ListMapper.listsWithRemote(remoteList).first {
                    Providers.listProvider.update(list, remote: false) {result in
                        if result.success {
                            postNotification(.List, verb, sender, list)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Update \(list)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Update list didn't return a list")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update list, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let listUuid = data as? String {
                Providers.listProvider.remove(listUuid, remote: false) {result in
                    if result.success {
                        postNotification(.List, verb, sender, listUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(listUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete list, data: \(data)")
            }
            
        case WSNotificationVerb.Invite:
            if let remoteListInvitation = RemoteListInvitation(representation: data) {
                postNotification(.List, verb, sender, remoteListInvitation)
            } else {
                QL4("Couldn't parse data: \(data)")
            }
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processListItem(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            if let remoteListItems = RemoteListItems(representation: data) {
                if let listItem = ListItemMapper.listItemsWithRemote(remoteListItems, sortOrderByStatus: nil).listItems.first {
                    Providers.listItemsProvider.add(listItem, remote: false) {result in
                        if result.success {
                            postNotification(.ListItem, verb, sender, listItem)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Add \(listItem)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Add list item didn't return a list")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add list item, data: \(data)")
            }

        case WSNotificationVerb.Update:
            if let remoteListItems = RemoteListItems(representation: data) {
                if let listItem = ListItemMapper.listItemsWithRemote(remoteListItems, sortOrderByStatus: nil).listItems.first {
                    Providers.listItemsProvider.update(listItem, remote: false) {result in
                        if result.success {
                            postNotification(.ListItem, verb, sender, listItem)
                        } else {
                            MyWebsocketDispatcher.reportWebsocketStoringError("Update \(listItem)", result: result)
                        }
                    }
                } else {
                    reportWebsocketGeneralError("Update list item didn't return a list")
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update list item, data: \(data)")
            }
            
        case WSNotificationVerb.Increment:
            if let remoteIncrement = RemoteIncrement(representation: data) {
                let increment = ItemIncrement(delta: remoteIncrement.delta, itemUuid: remoteIncrement.uuid) // TODO!!!! pass the last update timestamp also?
                Providers.listItemsProvider.increment(increment, remote: false) {result in
                    if result.success {
                        postNotification(.GroupItem, verb, sender, increment)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Increment list item \(remoteIncrement)", result: result)
                    }
                }
                
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update list item, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let containedItemIdentifier = RemoteContainedItemIdentifier(representation: data) {
                Providers.listItemsProvider.removeListItem(containedItemIdentifier.itemUuid, listUuid: containedItemIdentifier.containerUuid, remote: false) {result in
                    if result.success {
                        postNotification(.ListItem, verb, sender, containedItemIdentifier.itemUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete \(containedItemIdentifier)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete listitem, data: \(data)")
            }
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processSection(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
            // Not used as it's not possible to add sections directly
//        case WSNotificationVerb.Add:
//            let group = ListItemParser.parseSection(data)
//            postNotification(.Section, verb, group)
            
        case WSNotificationVerb.Update:
            if let remoteSection = RemoteSectionWithDependencies(representation: data) {
                let list = ListMapper.listWithRemote(remoteSection.list)
                let section = SectionMapper.SectionWithRemote(remoteSection.section, list: list)
                Providers.sectionProvider.update(section, remote: false) {result in
                    if result.success {
                        postNotification(.Section, verb, sender, section)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Update section \(section)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update section, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let sectionUuid = data as? String {
                Providers.sectionProvider.remove(sectionUuid, remote: false) {result in
                    if result.success {
                        postNotification(.Section, verb, sender, sectionUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete section \(sectionUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete section, data: \(data)")
            }

        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processInventory(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            if let remoteInventory = RemoteInventory(representation: data) {
                let inventory = InventoryMapper.inventoryWithRemote(remoteInventory)
                Providers.inventoryProvider.addInventory(inventory, remote: false) {result in
                    if result.success {
                        postNotification(.Inventory, verb, sender, inventory)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Add inventory \(inventory)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add inventory, data: \(data)")
            }
            
        case WSNotificationVerb.Update:
            if let remoteInventory = RemoteInventory(representation: data) {
                let inventory = InventoryMapper.inventoryWithRemote(remoteInventory)
                Providers.inventoryProvider.updateInventory(inventory, remote: false) {result in
                    if result.success {
                        postNotification(.Inventory, verb, sender, inventory)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Add inventory \(inventory)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update inventory, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let inventoryUuid = data as? String {
                Providers.listProvider.remove(inventoryUuid, remote: false) {result in
                    if result.success {
                        postNotification(.Inventory, verb, sender, inventoryUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete inventory \(inventoryUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete inventory, data: \(data)")
            }
            
        case WSNotificationVerb.Invite:
            if let remoteInventoryInvitation = RemoteInventoryInvitation(representation: data) {
                postNotification(.Inventory, verb, sender, remoteInventoryInvitation)
            } else {
                QL4("Couldn't parse data: \(data)")
            }
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processInventories(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Update:
            if let remoteOrderUpdates = RemoteOrderUpdate.collection(data) {
                let orderUpdates = remoteOrderUpdates.map{OrderUpdate(uuid: $0.uuid, order: $0.order)}
                Providers.inventoryProvider.updateInventoriesOrder(orderUpdates, remote: false) {result in
                    if result.success {
                        postNotification(.Inventories, verb, sender, remoteOrderUpdates)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Update inventories order \(remoteOrderUpdates)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Update inventories order, data: \(data)")
            }
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////
    // TODO!!!! inventory items - there seem to be some inconsistencies / not implemented
    /////////////////////////////////////////////////////////////////////////////////

    private static func processInventoryItem(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            if let inventoryItemsWithHistoryAndDependencies = RemoteInventoryItemsWithHistoryAndDependencies(representation: data) {
                let (inventoryItems, historyItems) = InventoryItemMapper.itemsWithRemote(inventoryItemsWithHistoryAndDependencies)
                Providers.inventoryItemsProvider.addToInventoryLocal(inventoryItems, historyItems: historyItems) {result in
                    if result.success {
                        postNotification(.Inventory, verb, sender, inventoryItems)
                        postNotification(.HistoryItem, verb, sender, historyItems)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Add inventory/history item \(inventoryItemsWithHistoryAndDependencies)", result: result)
                    }
                }
                
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Add inventory/history item, data: \(data)")
            }
            
        case WSNotificationVerb.Update:
            QL4("TODO inventory item update, also server!") // TODO!!!!
//            let inventoryItem = WSInventoryParser.parseInventoryItem(data)
//            Providers.inventoryItemsProvider.updateInventoryItem(inventoryItem, remote: false) {result in
//                postNotification(.InventoryItem, verb, inventoryItem)
//            }
            
        case WSNotificationVerb.Increment:
            if let remoteIncrement = RemoteIncrement(representation: data) {
                let increment = ItemIncrement(delta: remoteIncrement.delta, itemUuid: remoteIncrement.uuid) // TODO!!!! pass the last update timestamp also?
                Providers.inventoryItemsProvider.incrementInventoryItem(increment, remote: false) {result in
                    if result.success {
                        postNotification(.InventoryItem, verb, sender, increment)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Increment inventory item \(remoteIncrement)", result: result)
                    }
                }

            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Increment inventory item, data: \(data)")
            }
            
        case WSNotificationVerb.Delete:
            if let containedItemIdentifier = RemoteContainedItemIdentifier(representation: data) {
                Providers.inventoryItemsProvider.removeInventoryItem(containedItemIdentifier.itemUuid, inventoryUuid: containedItemIdentifier.containerUuid, remote: false) {result in
                    if result.success {
                        postNotification(.InventoryItem, verb, sender, containedItemIdentifier.itemUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete inventory item \(containedItemIdentifier)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete inventory item, data: \(data)")
            }

        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    // TODO!!!! this seems to be used for move cart->history, it accepts a sequence!
    private static func processInventoryItems(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Add:
            QL4("TODO processInventoryItems")
//            let incr = WSInventoryParser.parseInventoryItemIncrement(data)
//            Providers.inventoryItemsProvider.incrementInventoryItem(incr, remote: false) {result in
//                if result.success {
//                    postNotification(.Inventory, verb, incr)
//                } else {
//                    MyWebsocketDispatcher.reportWebsocketStoringError("Add (increment) \(incr)", result: result)
//                }
//            }
            
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    private static func processHistoryItem(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Delete:
            if let historyItemUuid = data as? String {
                Providers.historyProvider.removeHistoryItem(historyItemUuid, remote: false) {result in
                    if result.success {
                        postNotification(.HistoryItem, verb, sender, historyItemUuid)
                    } else {
                        MyWebsocketDispatcher.reportWebsocketStoringError("Delete history item \(historyItemUuid)", result: result)
                    }
                }
            } else {
                MyWebsocketDispatcher.reportWebsocketParsingError("Delete history item, data: \(data)")
            }
            
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    private static func processShared(verb: WSNotificationVerb, _ topic: String, _ sender: String, _ data: AnyObject) {
        switch verb {
        case WSNotificationVerb.Sync:
            if let sender = data.valueForKeyPath("sender") as? String {
                
                postNotification(.SyncShared, verb, sender, sender)
            } else {
                QL4("No sender. Data: \(data)")
            }
            
        default: QL4("Not handled verb: \(verb)")
        }
    }
    
    
    //    private static func processPlanItem(verb: WSNotificationVerb, _ topic: String, _ data: AnyObject) {
    //        switch verb {
    //        case WSNotificationVerb.Add:
    //            let items = WSPlanItemParser.parsePlanItem(data) // TODO review do we need group items here? if yes are they sent?
    //            postNotification(.PlanItem, verb, items)
    //        case WSNotificationVerb.Update:
    //            let items = WSPlanItemParser.parsePlanItem(data)
    //            postNotification(.PlanItem, verb, items)
    //        case WSNotificationVerb.Delete:
    //            let items = WSPlanItemParser.parsePlanItem(data)
    //            postNotification(.PlanItem, verb, items)
    //        default: QL4("Not handled verb: \(verb)")
    //        }
    //    }
}
