//
//  RealmListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

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
        let filterMaybe = substring.map{DBListItemGroup.createFilterNameContains($0)}
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range) {groups in
            handler(substring: substring, groups: groups)
        }
    }

    // TODO remove
    func groups(handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
    
    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(group: ListItemGroup, dirty: Bool, handler: Bool -> Void) {
        update(group, dirty: dirty, handler: handler)
    }

    func update(group: ListItemGroup, dirty: Bool, handler: Bool -> Void) {
        let dbObj = ListItemGroupMapper.dbWith(group, dirty: dirty)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func update(groups: [ListItemGroup], dirty: Bool, handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0, dirty: dirty)}
        saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func updateGroupsOrder(orderUpdates: [OrderUpdate], dirty: Bool, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(DBListItemGroup.self, value: DBListItemGroup.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        }
    }
    
    func incrementFav(groupUuid: String, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let existingGroup = realm.objects(DBListItemGroup).filter(DBListItemGroup.createFilter(groupUuid)).first {
                existingGroup.fav += 1
                realm.add(existingGroup, update: true)
                return true
            } else { // product not found
                return false
            }
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func overwrite(groups: [ListItemGroup], clearTombstones: Bool, handler: Bool -> ()) {
        let dbGroups = groups.map{ListItemGroupMapper.dbWith($0)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveListItemGroup)} : nil
        self.overwrite(dbGroups, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func remove(group: ListItemGroup, markForSync: Bool, handler: Bool -> Void) {
        removeGroup(group.uuid, markForSync: markForSync, handler: handler)
    }

    func removeGroup(uuid: String, markForSync: Bool, handler: Bool -> Void) {
        // Needs custom handling because we need the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({[weak self] realm in
            self?.removeGroupSync(realm, groupUuid: uuid, markForSync: markForSync)
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func removeGroupSync(realm: Realm, groupUuid: String, markForSync: Bool) {
        
        removeGroupDependenciesSync(realm, groupUuid: groupUuid, markForSync: markForSync)
        
        if let itemToRemove = realm.objects(DBListItemGroup).filter(DBListItemGroup.createFilter(groupUuid)).first {
            if markForSync {
                let toRemove = DBRemoveListItemGroup(uuid: groupUuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                realm.add(toRemove, update: true)
            }
            realm.delete(itemToRemove)
            
            // Update order. No synchonisation with server for this, since server also reorders on delete, and on sync. Not sure right now if reorder on sync covers all cases specially for multiple devices, for now looks sufficient.
            let allSortedDbGroups = realm.objects(DBListItemGroup).sort({$0.order < $1.order})
            let updatedDbGroups: [DBListItemGroup] = allSortedDbGroups.mapEnumerate {(index, dbList) in
                dbList.order = index
                return dbList
            }
            for updatedDbGroup in updatedDbGroups {
                realm.create(DBListItemGroup.self, value: ["uuid": updatedDbGroup.uuid, "order": updatedDbGroup.order], update: true)
            }

        } else {
            QL1("No group to remove: uuid: \(groupUuid)")
        }
    }
    
    func removeGroupDependenciesSync(realm: Realm, groupUuid: String, markForSync: Bool) {
        DBProviders.groupItemProvider.removeGroupItemsForGroupSync(realm, groupUuid: groupUuid, markForSync: markForSync)
    }
    
    
    // MARK: - Sync

    func clearGroupTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItemGroup.self, DBRemoveListItemGroup.createFilter(uuid))
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
    
    func updateLastSyncTimeStampSync(realm: Realm, group: RemoteGroup) {
        realm.create(DBListItemGroup.self, value: group.timestampUpdateDict, update: true)
    }
}