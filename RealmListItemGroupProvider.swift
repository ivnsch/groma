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
    
    func overwrite(groups: [ListItemGroup], clearTombstones: Bool, handler: Bool -> ()) {
        let dbGroups = groups.map{ListItemGroupMapper.dbWith($0)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBListItemGroup)} : nil
        self.overwrite(dbGroups, resetLastUpdateToServer: true, additionalActions: additionalActions, handler: handler)
    }
    
    func remove(group: ListItemGroup, markForSync: Bool, handler: Bool -> Void) {
        removeGroup(group.uuid, markForSync: markForSync, handler: handler)
    }

    func removeGroup(uuid: String, markForSync: Bool, handler: Bool -> Void) {
        // Needs custom handling because we need the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({realm in
            if let itemToRemove = realm.objects(DBListItemGroup).filter(DBListItemGroup.createFilter(uuid)).first {
                realm.delete(itemToRemove)
                if markForSync {
                    let toRemove = DBRemoveListItemGroup(uuid: uuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                    realm.add(toRemove, update: true)
                }
            }
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
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