//
//  WSItemsSaver.swift
//  shoppin
//
//  Created by ischuetz on 10/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class WSItemsSaver {

    init() {
        for (notificationName, selector) in [
            (WSNotificationName.ListItems.rawValue, "onWebsocketListItems:"),
            (WSNotificationName.ListItem.rawValue, "onWebsocketListItem:"),
            (WSNotificationName.List.rawValue, "onWebsocketList:"),
            (WSNotificationName.Product.rawValue, "onWebsocketProduct:"),
            (WSNotificationName.Group.rawValue, "onWebsocketGroup:"),
            (WSNotificationName.GroupItem.rawValue, "onWebsocketGroupItem:"),
            (WSNotificationName.Section.rawValue, "onWebsocketSection:"),
            (WSNotificationName.Inventory.rawValue, "onWebsocketInventory:"),
            (WSNotificationName.InventoryItems.rawValue, "onWebsocketInventoryItems:"),
            (WSNotificationName.InventoryItem.rawValue, "onWebsocketInventoryItem:"),
            (WSNotificationName.InventoryItemsWithHistory.rawValue, "onWebsocketInventoryItemsWithHistory:"),
            (WSNotificationName.HistoryItem.rawValue, "onWebsocketHistoryItem:")
            ] {
          NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector(selector), name: notificationName, object: nil)
        }
    }
    
    private func parse<T>(note: NSNotification, isTry: Bool = false, function: WSNotification<T> -> Void) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<T>> {
            if let notification = info[WSNotificationValue] {
                function(notification)
            } else {
                print("Error: WSItemsSaver.onWebsocketListItems: no value. \(note.name)")
            }
        } else if !isTry {
            print("Error: WSItemsSaver.onWebsocketListItems: no userInfo or wrong type. Note: \(note.name), type: \(T.self)")
        }
    }
    
    private func tryParse<T>(note: NSNotification, function: WSNotification<T> -> Void) {
        parse(note, isTry: true, function: function)
    }
    
    func onWebsocketListItems(note: NSNotification) {
        parse(note) {(notification: WSNotification<[ListItem]>) in
            switch notification.verb {
            case WSNotificationVerb.Update:
                Providers.listItemsProvider.update(notification.obj, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItems: Couldn't save item")
                    }
                }
                
            default: print("Error: WSItemsSaver.onWebsocketListItems: Not handled: \(notification.verb)")
            }
        }
    }
    
    func onWebsocketListItem(note: NSNotification) {
        parse(note) {(notification: WSNotification<ListItem>) in
            let listItem = notification.obj
            switch notification.verb {
            case .Add:
                Providers.listItemsProvider.add(listItem, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't add item")
                    }
                }
            case .Update:
                Providers.listItemsProvider.update(listItem, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.listItemsProvider.remove(listItem, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't delete item")
                    }
                }
            }
        }
    }
    
    func onWebsocketList(note: NSNotification) {
        parse(note) {(notification: WSNotification<List>) in
            let list = notification.obj
            switch notification.verb {
            case .Add:
                Providers.listProvider.add(list, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketList: Couldn't add item")
                    }
                }
            case .Update:
                Providers.listProvider.update(list, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketList: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.listProvider.remove(list, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketList: Couldn't delete item")
                    }
                }
            }
        }
    }

    func onWebsocketProduct(note: NSNotification) {
        parse(note) {(notification: WSNotification<Product>) in
            let product = notification.obj
            switch notification.verb {
            case .Add:
                Providers.productProvider.add(product, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't add item")
                    }
                }
            case .Update:
                Providers.productProvider.update(product, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.productProvider.delete(product, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketListItem: Couldn't delete item")
                    }
                }
            }
        }
    }
    
    func onWebsocketGroup(note: NSNotification) {
        parse(note) {(notification: WSNotification<ListItemGroup>) in
            let group = notification.obj
            switch notification.verb {
            case .Add:
                Providers.listItemGroupsProvider.add(group, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketGroup: Couldn't add item")
                    }
                }
            case .Update:
                Providers.listItemGroupsProvider.update(group, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketGroup: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.listItemGroupsProvider.remove(group, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketGroup: Couldn't delete item")
                    }
                }
            }
        }
    }
    
    func onWebsocketGroupItem(note: NSNotification) {
        parse(note) {(notification: WSNotification<GroupItemWithGroup>) in
            let groupItemWithGroup = notification.obj
            switch notification.verb {
                // for now not implemented as we don't add single group items, user always has to confirm on the group. Also, we don't have group here which is required by the provider
//            case .Add:
//                Providers.listItemGroupsProvider.add(group, remote: false) {result in
//                    if !result.success {
//                        print("Error WSItemsSaver.onWebsocketGroup: Couldn't add item")
//                    }
//                }
            case .Update:
                Providers.listItemGroupsProvider.update(groupItemWithGroup.groupItem, group: groupItemWithGroup.group, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketGroupItems: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.listItemGroupsProvider.remove(groupItemWithGroup.groupItem, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketGroupItems: Couldn't delete item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketInventory: Not handled: \(notification.verb)")

            }
        }
    }
    
    func onWebsocketSection(note: NSNotification) {
        parse(note) {(notification: WSNotification<Section>) in
            let section = notification.obj
            switch notification.verb {
            case .Add:
                Providers.sectionProvider.add(section, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketSection: Couldn't add item")
                    }
                }
            case .Update:
                Providers.sectionProvider.update([section], remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketSection: Couldn't update item")
                    }
                }
            case .Delete:
                Providers.sectionProvider.remove(section, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketSection: Couldn't delete item")
                    }
                }
            }
        }
    }
    
    func onWebsocketInventory(note: NSNotification) {
        parse(note) {(notification: WSNotification<Inventory>) in
            let inventory = notification.obj
            switch notification.verb {
            case .Add:
                Providers.inventoryProvider.addInventory(inventory, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketInventory: Couldn't add item")
                    }
                }
            case .Update:
                Providers.inventoryProvider.updateInventory(inventory, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketInventory: Couldn't update item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketInventory: Not handled: \(notification.verb)")
            }
        }
    }
    
    func onWebsocketInventoryItems(note: NSNotification) {
        parse(note) {(notification: WSNotification<InventoryItemIncrement>) in
            switch notification.verb {
            case .Add:
                Providers.inventoryItemsProvider.incrementInventoryItem(notification.obj, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.incrementInventoryItem: Couldn't increment item")
                    }
                }
            default: print("Error: WSItemsSaver.incrementInventoryItem: Not handled: \(notification.verb)")
            }
        }
    }
    
    func onWebsocketInventoryItem(note: NSNotification) {
        parse(note) {(notification: WSNotification<InventoryItem>) in
            switch notification.verb {
            case .Update:
                Providers.inventoryItemsProvider.updateInventoryItem(notification.obj, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketInventoryItem: Couldn't update item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketInventoryItem: Not handled: \(notification.verb)")
            }
        }
        parse(note) {(notification: WSNotification<InventoryItemId>) in
            switch notification.verb {
            case .Delete:
                Providers.inventoryItemsProvider.removeInventoryItem(notification.obj.productUuid, inventoryUuid: notification.obj.inventoryUuid, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketInventoryItem: Couldn't update item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketInventoryItem: Not handled: \(notification.verb)")
            }
        }
        // .Add - TODO? increment is covered in onWebsocketInventoryItems, but user can e.g. change name (update of product in this case, but still triggered from inventory...)
    }
    
    func onWebsocketInventoryItemsWithHistory(note: NSNotification) {
        parse(note) {(notification: WSNotification<[InventoryItemWithHistoryEntry]>) in
            let items = notification.obj
            switch notification.verb {
            case .Add:
                Providers.inventoryItemsProvider.addToInventory(items, remote: false) {result in
                    // here the controller wants to reload the items (with pagination it's complicated to just append them) so we send notification after saved
                    if result.success {
                        MyWebsocketDispatcher.postEmptyNotification(.InventoryItemsWithHistoryAfterSave, .Add)
                    } else {
                        print("Error WSItemsSaver.onWebsocketInventoryItemsWithHistory: Couldn't add item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketInventoryItemsWithHistory: Not handled: \(notification.verb)")            }
        }
    }
    
    func onWebsocketHistoryItem(note: NSNotification) {
        parse(note) {(notification: WSNotification<String>) in
            let historyItemUuid = notification.obj
            switch notification.verb {

            case .Delete:
                Providers.historyProvider.removeHistoryItem(historyItemUuid, remote: false) {result in
                    if !result.success {
                        print("Error WSItemsSaver.onWebsocketHistoryItem: Couldn't delete item")
                    }
                }
            default: print("Error: WSItemsSaver.onWebsocketHistoryItem: Not handled: \(notification.verb)")
            }
        }
    }
}
