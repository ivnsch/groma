//
//  RealmProductGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class RealmProductGroupProvider: RealmProvider {
    
    // TODO don't use QuickAddItemSortBy here, map to a (new) group specific enum
    func groups(_ range: NSRange, sortBy: GroupSortBy, handler: @escaping ([ProductGroup]) -> Void) {
        groups(range: range, sortBy: sortBy) {tuples in
            handler(tuples.1)
        }
    }
    
    func groups(_ substring: String? = nil, range: NSRange? = nil, sortBy: GroupSortBy, handler: @escaping ((substring: String?, groups: [ProductGroup])) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            case .order: return ("order", true)
            }
        }()
        
        
        withRealm({realm -> [String]? in
            let filterMaybe: NSPredicate? = substring.flatMap {
                $0.isEmpty ? nil : ProductGroup.createFilterNameContains($0)
            }
            let groups: Results<ProductGroup> = self.loadSync(realm, predicate: filterMaybe,
                                                              sortDescriptor: NSSortDescriptor(key: sortData.key,
                                                                                               ascending: sortData.ascending))
            return groups.toArray(range).map{$0.uuid}
            
        }) {uuidsMaybe in
            do {
                if let uuids = uuidsMaybe {
                    let realm = try RealmConfig.realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let groups: Results<ProductGroup> = self.loadSync(realm, predicate: ProductGroup.createFilterUuids(uuids),
                                                                      sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending))
                    let groupsArray: [ProductGroup] = groups.toArray()
                    handler((substring, groupsArray))
                    
                } else {
                    logger.e("No product uuids")
                    handler((substring, []))
                }
                
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                handler((substring, []))
            }
        }
    }

    func groups(sortBy: GroupSortBy, _ handler: @escaping (Results<ProductGroup>?) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            case .order: return ("order", true)
            }
        }()
        handler(loadSync(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)))
    }
    
    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(_ group: ProductGroup, dirty: Bool, handler: @escaping (Bool) -> Void) {
        update(group, dirty: dirty, handler: handler)
    }

    func update(_ group: ProductGroup, dirty: Bool, handler: @escaping (Bool) -> Void) {
        saveObj(group.copy(), update: true, handler: handler)
    }
    
    func update(_ groups: [ProductGroup], dirty: Bool, handler: @escaping (Bool) -> Void) {
        saveObjs(groups.map{$0.copy()}, update: true, handler: handler)
    }
    
    func updateGroupsOrder(_ orderUpdates: [OrderUpdate], dirty: Bool, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(ProductGroup.self, value: ProductGroup.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        }
    }
    
    func incrementFav(_ groupUuid: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let existingGroup = realm.objects(ProductGroup.self).filter(ProductGroup.createFilter(groupUuid)).first {
                existingGroup.fav += 1
                realm.add(existingGroup, update: true)
                return true
            } else { // group not found
                logger.e("Didn't find group to increment fav")
                return false
            }
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func overwrite(_ groups: [ProductGroup], clearTombstones: Bool, handler: @escaping (Bool) -> ()) {
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveProductGroup.self)} : nil
        let groupsCopy: [ProductGroup] = groups.map{$0.copy()}
        self.overwrite(groupsCopy, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func remove(_ group: ProductGroup, markForSync: Bool, handler: @escaping (Bool) -> Void) {
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
        
        if let itemToRemove = realm.objects(ProductGroup.self).filter(ProductGroup.createFilter(groupUuid)).first {
            if markForSync {
                let toRemove = DBRemoveProductGroup(uuid: groupUuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                realm.add(toRemove, update: true)
            }
            realm.delete(itemToRemove)
            
            // Update order. No synchonisation with server for this, since server also reorders on delete, and on sync. Not sure right now if reorder on sync covers all cases specially for multiple devices, for now looks sufficient.
            let allSortedDbGroups = realm.objects(ProductGroup.self).sorted(by: {$0.order < $1.order})
            let updatedDbGroups: [ProductGroup] = allSortedDbGroups.mapEnumerate {(index, dbList) in
                dbList.order = index
                return dbList
            }
            for updatedDbGroup in updatedDbGroups {
                realm.create(ProductGroup.self, value: ["uuid": updatedDbGroup.uuid, "order": updatedDbGroup.order], update: true)
            }

        } else {
            logger.v("No group to remove: uuid: \(groupUuid)")
        }
    }
    
    func removeGroupDependenciesSync(_ realm: Realm, groupUuid: String, markForSync: Bool) {
        _ = DBProv.groupItemProvider.removeGroupItemsForGroupSync(realm, groupUuid: groupUuid, markForSync: markForSync)
    }
    
    
    // MARK: - Sync

    func clearGroupTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveProductGroup.self, DBRemoveProductGroup.createFilter(uuid))
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
        realm.create(ProductGroup.self, value: group.timestampUpdateDict, update: true)
    }
}
