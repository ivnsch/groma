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
    func groups(_ range: NSRange, sortBy: GroupSortBy, handler: @escaping ([ListItemGroup]) -> Void) {
        groups(range: range, sortBy: sortBy) {tuples in
            handler(tuples.1)
        }
    }
    
    func groups(_ substring: String? = nil, range: NSRange? = nil, sortBy: GroupSortBy, handler: @escaping ((substring: String?, groups: [ListItemGroup])) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            case .order: return ("order", true)
            }
        }()
        let filterMaybe = substring.map{DBListItemGroup.createFilterNameContains($0)}
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range) {groups in
            handler((substring, groups))
        }
    }

    // TODO remove
    func groups(_ handler: @escaping ([ListItemGroup]) -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
    
    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(_ group: ListItemGroup, dirty: Bool, handler: @escaping (Bool) -> Void) {
        update(group, dirty: dirty, handler: handler)
    }

    func update(_ group: ListItemGroup, dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbObj = ListItemGroupMapper.dbWith(group, dirty: dirty)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func update(_ groups: [ListItemGroup], dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0, dirty: dirty)}
        saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func updateGroupsOrder(_ orderUpdates: [OrderUpdate], dirty: Bool, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(DBListItemGroup.self, value: DBListItemGroup.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        }
    }
    
    func incrementFav(_ groupUuid: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let existingGroup = realm.objects(DBListItemGroup.self).filter(DBListItemGroup.createFilter(groupUuid)).first {
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
    
    func overwrite(_ groups: [ListItemGroup], clearTombstones: Bool, handler: @escaping (Bool) -> ()) {
        let dbGroups = groups.map{ListItemGroupMapper.dbWith($0)}
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveListItemGroup.self)} : nil
        self.overwrite(dbGroups, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func remove(_ group: ListItemGroup, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        removeGroup(group.uuid, markForSync: markForSync, handler: handler)
    }

    func removeGroup(_ uuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        // Needs custom handling because we need the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({[weak self] realm in
            self?.removeGroupSync(realm, groupUuid: uuid, markForSync: markForSync)
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func removeGroupSync(_ realm: Realm, groupUuid: String, markForSync: Bool) {
        
        removeGroupDependenciesSync(realm, groupUuid: groupUuid, markForSync: markForSync)
        
        if let itemToRemove = realm.objects(DBListItemGroup.self).filter(DBListItemGroup.createFilter(groupUuid)).first {
            if markForSync {
                let toRemove = DBRemoveListItemGroup(uuid: groupUuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                realm.add(toRemove, update: true)
            }
            realm.delete(itemToRemove)
            
            // Update order. No synchonisation with server for this, since server also reorders on delete, and on sync. Not sure right now if reorder on sync covers all cases specially for multiple devices, for now looks sufficient.
            let allSortedDbGroups = realm.objects(DBListItemGroup.self).sorted(by: {$0.order < $1.order})
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
    
    func removeGroupDependenciesSync(_ realm: Realm, groupUuid: String, markForSync: Bool) {
        _ = DBProviders.groupItemProvider.removeGroupItemsForGroupSync(realm, groupUuid: groupUuid, markForSync: markForSync)
    }
    
    
    // MARK: - Sync

    func clearGroupTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItemGroup.self, DBRemoveListItemGroup.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    

    func updateLastSyncTimeStamp(_ group: RemoteGroup, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, group: group)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(_ groups: [RemoteGroup], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            for group in groups {
                self?.updateLastSyncTimeStampSync(realm, group: group)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(_ realm: Realm, group: RemoteGroup) {
        realm.create(DBListItemGroup.self, value: group.timestampUpdateDict, update: true)
    }
}
