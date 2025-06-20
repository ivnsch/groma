//
//  RealmItemProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import UIKit
import RealmSwift


class RealmItemProvider: RealmProvider {

    func items(sortBy: ProductSortBy, handler: @escaping (Results<Item>?) -> Void) {
        // For now duplicate code with products, to use Results and plain objs api together (for search text for now it's easier to use plain obj api)
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        handler(loadSync(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)))
    }
    
    // IMPORTANT: This cannot be used for real time updates (add) since the final results are fetched using uuids, so these results don't notice items with new uuids
    func items(_ substring: String, onlyEdible: Bool, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ items: Results<Item>?) -> Void) {
        
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = onlyEdible ? Item.createFilterNameContainsAndEdible(substring, edible: onlyEdible) :
            (substring.isEmpty ? nil : Item.createFilterNameContains(substring))

        background({() -> [String]? in
            do {
                let realm = try RealmConfig.realm()
                let items: [Item] = self.loadSync(realm, predicate: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
                return items.map{$0.uuid}
            } catch let e {
                logger.e("Error creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {itemUuidsMaybe in
            do {
                if let itemUuids = itemUuidsMaybe {
                    let realm = try RealmConfig.realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let items: Results<Item> = self.loadSync(realm,
                                                             predicate: Item.createFilterUuids(itemUuids),
                                                             sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending))
                    handler(substring, items)
                    
                } else {
                    logger.e("No item uuids")
                    handler(substring, nil)
                }
                
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                handler(substring, nil)
            }
        })
        
    }
    
    func items(names: [String]) -> ProvResult<Results<Item>, DatabaseError> {
        let resultMaybe = withRealmSync({realm -> ProvResult<Results<Item>, DatabaseError>? in
            return .ok(realm.objects(Item.self).filter(Item.createFilter(names: names)))
        })
        
        return resultMaybe ?? .err(.unknown)
    }

    
    func find(name: String, _ handler: @escaping (ProvResult<Item?, DatabaseError>) -> Void) {
        handler(findSync(name: name))
    }
    
    func addOrUpdate(input: ItemInput, _ handler: @escaping ((Item, Bool)?) -> Void) {
        switch mergeOrCreateItemSync(itemInput: input, updateCategory: true, doTransaction: true, notificationTokens: []) {
        case .ok(let item, let isNew):
            handler((item, isNew))
        case .err(let error):
            logger.e("Error in merge or create item: \(error)")
            handler(nil)
        }
    }
    
    func delete(uuid: String, realmData: RealmData, handler: @escaping (Bool) -> Void) {
        handler(deleteSync(uuid: uuid, realmData: realmData))
    }

    func delete(name: String, handler: @escaping (Bool) -> Void) {
        handler(deleteSync(name: name))
    }
    
    func incrementFav(itemUuid: String, transactionRealm: Realm? = nil,  _ handler: @escaping (Bool) -> Void) {
        
        func transactionContent(realm: Realm) -> Bool {
            if let existingItem = realm.objects(Item.self).filter(Item.createFilter(uuid: itemUuid)).first {
                existingItem.fav += 1
                realm.add(existingItem, update: true)
                return true
            } else { // product not found
                return false
            }
        }
        
        if let realm = transactionRealm {
            _ = transactionContent(realm: realm)
        } else {
            doInWriteTransaction({realm in
                return transactionContent(realm: realm)
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
            })
        }
    }
    
    // MARK: - Sync
    
    func findSync(name: String) -> ProvResult<Item?, DatabaseError> {
        let resultMaybe = withRealmSync({realm -> ProvResult<Item?, DatabaseError>? in
            return .ok(realm.objects(Item.self).filter(Item.createFilter(name: name)).first)
        })
        
        return resultMaybe ?? .err(.unknown)
    }
    
//    func addOrUpdateSync(input: ItemInput) -> Bool {
//        let existingItemMaybe = findSync(name: input.name)
//        
//        if existingItemMaybe.isOk {
//            logger.v("Item already exists")
//            // There's nothing to update now so we just return true
//            return true
//            
//        } else {
//            let writeSuccess: Bool? = self.doInWriteTransactionSync({realm in
//                let item = Item(uuid: UUID().uuidString, name: input.name, category: input.category, fav: 0)
//                realm.add(item, update: true)
//                return true
//            })
//            
//            return writeSuccess ?? false
//            
//        }
//    }
    
    func deleteSync(name: String) -> Bool {
        return deleteItemsSync(predicate: Item.createFilter(name: name), realmData: nil) // TODO? realm data
    }
    
    func deleteSync(uuid: String, realmData: RealmData) -> Bool {
        return deleteItemsSync(predicate: Item.createFilter(uuid: uuid), realmData: realmData)
    }
    
    fileprivate func deleteItemsSync(predicate: NSPredicate, realmData: RealmData?) -> Bool {
        return doInWriteTransactionSync(realmData: realmData) {realm -> Bool in
            if let item = realm.objects(Item.self).filter(predicate).first {
                _ = DBProv.productProvider.deleteProductsAndDependenciesSync(realm, itemUuid: item.uuid, markForSync: true)
                _ = DBProv.ingredientProvider.deleteIngredientsAndDependenciesSync(realm: realm, itemUuid: item.uuid)
                realm.delete(item)
                return true
                
            } else {
                logger.w("Didn't find item with predicate: \(predicate) to be deleted. Do nothing.")
                return true // Don't see a particular reason to show the user an error here, so we just log a warning and return success.
            }
        } ?? false
    }
    
    // TODO!!!!!!!!!!!!!!! orient maybe with similar method in product for transaction etc. Product also needs refactoring though
    // load item and update or create one
    // if we find an item with the unique we update it - this is for the case the user changes category color etc for an existing item while adding it
    // NOTE: This doesn't save anything to the database (no particular reason, except that the current caller of this method does the saving)
    // Returns tuple with item and whether it's new (was created) or already existed
    func mergeOrCreateItemSync(itemInput: ItemInput, updateCategory: Bool, doTransaction: Bool, saveItem: Bool = false, notificationTokens: [NotificationToken]) -> ProvResult<(Item, Bool), DatabaseError> {

        func transactionContent() -> ProvResult<(Item, Bool), DatabaseError> {
            
            // Always fetch/create category (whether item already exists or not), since we need to ensure we have the category identified by unique from prototype, which is not necessarily the same as the one referenced by existing item (we want to update only non-unique properties).
            return DBProv.productCategoryProvider.mergeOrCreateCategorySync(categoryInput: itemInput.categoryInput, doTransaction: false, notificationTokens: notificationTokens).flatMap {category in
                
                switch findSync(name: itemInput.name) {
                case .ok(let itemMaybe):
                    if let item = itemMaybe {
                        item.edible = itemInput.edible
                        item.category = category    
                        return .ok((item, false))
                        
                    } else { // item doesn't exist
                        
                        let newItem = Item(uuid: UUID().uuidString, name: itemInput.name, category: category, fav: 0, edible: itemInput.edible)
                        withRealmSync({realm in
                            realm.add(newItem, update: true)
                        })
                        return .ok((newItem, true))
                  }
                case .err(let error): return .err(error)
                }
            }
        }
        
        if doTransaction {
            return doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: nil) {realm in
                return transactionContent()
            } ?? .err(.unknown)
        } else {
            return transactionContent()
        }
    }

    
}
