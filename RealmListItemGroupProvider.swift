//
//  RealmListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmListItemGroupProvider: RealmProvider {
    
    // TODO don't use QuickAddItemSortBy here, map to a (new) group specific enum
    func groups(range: NSRange, sortBy: GroupSortBy, handler: [ListItemGroup] -> Void) {
        groups(range: range, sortBy: sortBy) {tuples in
            handler(tuples.groups)
        }
    }
    
    func groups(substring: String? = nil, range: NSRange? = nil, sortBy: GroupSortBy, handler: (substring: String?, groups: [ListItemGroup]) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .Alphabetic: return ("name", true)
            case .Fav: return ("fav", false)
            case .Order: return ("order", true)
            }
        }()
        let filterMaybe = substring.map{"name CONTAINS[c] '\($0)'"}
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range) {groups in
            handler(substring: substring, groups: groups)
        }
    }
    
    func groupItems(group: ListItemGroup, handler: [GroupItem] -> Void) {
        let mapper = {GroupItemMapper.groupItemWith($0)}
        self.load(mapper, filter: "group.uuid = '\(group.uuid)'", handler: handler)
    }

    // TODO remove
    func groups(handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
    
    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(group: ListItemGroup, handler: Bool -> Void) {
        update(group, handler: handler)
    }

    func update(group: ListItemGroup, handler: Bool -> Void) {
        let dbObj = ListItemGroupMapper.dbWith(group)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func update(groups: [ListItemGroup], handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0)}
        saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func remove(group: ListItemGroup, handler: Bool -> Void) {
        removeGroup(group.uuid, handler: handler)
    }

    func removeGroup(uuid: String, handler: Bool -> Void) {
        self.remove("uuid = '\(uuid)'", handler: handler, objType: DBListItemGroup.self)
    }
    
    func add(groupItem: GroupItem, handler: Bool -> Void) {
        addOrUpdate(groupItem, handler: handler)
    }

    func addOrIncrement(groupItems: [GroupItem], handler: Bool -> Void) {
        
        func addOrIncrement(groupItems: [GroupItem]) -> Bool {
            do {
                // load items
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                let groupItemsUuidsStr: String = groupItems.map{"'\($0.uuid)'"}.joinWithSeparator(",")
                
                let items = loadSync(realm, mapper: mapper, filter: "uuid IN {\(groupItemsUuidsStr)}")
                // decide if add/increment
                let dict: [String: GroupItem] = items.toDictionary{($0.uuid, $0)}
                let newOrIncrementedGroupItems: [DBGroupItem] = groupItems.map {groupItem in
                    let item: GroupItem = {
                        if let storedGroupItem = dict[groupItem.uuid] { // item exists - update existing one with incremented copy
                            return storedGroupItem.incrementQuantityCopy(groupItem.quantity)
                        } else { // item doesn't exist - create a new one
                            return groupItem
                        }
                    }()
                    return GroupItemMapper.dbWith(item)
                }
                //save
                saveObjsSync(newOrIncrementedGroupItems, update: true)
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(success: Bool) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItems)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(false)
            }
        })
    }
    
    func addOrIncrement(groupItem: GroupItem, handler: Bool -> Void) {
        
        func addOrIncrement(item: GroupItem) -> Bool {
            do {
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                if let item = loadSync(realm, mapper: mapper, filter: "product.name = '\(groupItem.product.name)' && group.uuid = '\(groupItem.group.uuid)'").first {
                    let incremented = item.incrementQuantityCopy(groupItem.quantity)
                    let dbItem = GroupItemMapper.dbWith(incremented)
                    saveObjSync(dbItem, update: true)
                } else {
                    let dbItem = GroupItemMapper.dbWith(groupItem)
                    saveObjSync(dbItem, update: true)
                }
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(success: Bool) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItem)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(false)
            }
        })
    }
    
    func update(groupItem: GroupItem, handler: Bool -> Void) {
        addOrUpdate(groupItem, handler: handler)
    }
    
    func addOrUpdate(groupItem: GroupItem, handler: Bool -> Void) {
        let dbObj = GroupItemMapper.dbWith(groupItem)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(groupItem: GroupItem, handler: Bool -> Void) {
        removeGroupItem(groupItem.uuid, handler: handler)
    }

    func removeGroupItem(uuid: String, handler: Bool -> Void) {
        remove("uuid = '\(uuid)'", handler: handler, objType: DBGroupItem.self)
    }
    
    // Copied from realm list item provider (which is copied from inventory item provider) refactor?
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    func incrementGroupItem(item: GroupItem, delta: Int, handler: Bool -> ()) {
        
        //        synced(self)  {
        
        // load
        let realm = try! Realm()
        let results = realm.objects(DBGroupItem).filter("uuid == '\(item.uuid)'")
        //        results = results.filter(NSPredicate(format: DBInventoryItem.createFilter(item.product, item.inventory), argumentArray: []))
        let objs: [DBGroupItem] = results.toArray(nil)
        let dbItems = objs.map{GroupItemMapper.groupItemWith($0)}
        let groupItemMaybe = dbItems.first
        
        if let groupItem = groupItemMaybe {
            // increment
            let incrementedListitem = groupItem.copy(quantity: groupItem.quantity + delta)
            
            // convert to db object
            let dbIncrementedInventoryitem = GroupItemMapper.dbWith(incrementedListitem)
            
            // save
            realm.write {
                for obj in objs {
                    obj.lastUpdate = NSDate()
                    realm.add(dbIncrementedInventoryitem, update: true)
                }
            }
            
            handler(true)
            
            
        } else {
            print("Info: RealmListItemGroupProvider.incrementGroupItem: Group item not found: \(item)")
            handler(false)
        }
        //        }
    }
    
    
    func updateLastSyncTimeStamp(items: RemoteGroupItemsWithDependencies, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            for listItem in items.groupItems {
                realm.create(DBGroupItem.self, value: listItem.timestampUpdateDict, update: true)
            }
            for product in items.products {
                realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in items.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for group in items.groups {
                self?.updateLastSyncTimeStampSync(realm, group: group)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    func updateLastSyncTimeStamp(group: RemoteGroup, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, group: group)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(groups: [RemoteGroup], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            for group in groups {
                self?.updateLastSyncTimeStampSync(realm, group: group)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    private func updateLastSyncTimeStampSync(realm: Realm, group: RemoteGroup) {
        realm.create(DBListItemGroup.self, value: group.timestampUpdateDict, update: true)
    }
}