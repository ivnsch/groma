//
//  RealmItemProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

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
    func items(_ substring: String, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ items: Results<Item>?) -> Void) {
        
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = Item.createFilterNameContains(substring)
        
        background({() -> [String]? in
            do {
                let realm = try Realm()
                let items: [Item] = self.loadSync(realm, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
                return items.map{$0.uuid}
            } catch let e {
                QL4("Error creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {itemUuidsMaybe in
            do {
                if let itemUuids = itemUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let items: Results<Item> = self.loadSync(realm, filter: Item.createFilterUuids(itemUuids), sortDescriptor: SortDescriptor(keyPath: sortData.key, ascending: sortData.ascending))
                    handler(substring, items)
                    
                } else {
                    QL4("No item uuids")
                    handler(substring, nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(substring, nil)
            }
        })
        
    }
    
    func find(name: String, _ handler: @escaping (ProvResult<Item?, DatabaseError>) -> Void) {
        handler(findSync(name: name))
    }
    
    func addOrUpdate(input: ItemInput, _ handler: @escaping (Bool) -> Void) {
//        handler(addOrUpdateSync(input: input))
    }
    
    func delete(uuid: String, realmData: RealmData, handler: @escaping (Bool) -> Void) {
        handler(deleteSync(uuid: uuid, realmData: realmData))
    }

    func delete(name: String, handler: @escaping (Bool) -> Void) {
        handler(deleteSync(name: name))
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
//            QL1("Item already exists")
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
        return deleteItemsSync(filter: Item.createFilter(name: name), realmData: nil) // TODO? realm data
    }
    
    func deleteSync(uuid: String, realmData: RealmData) -> Bool {
        return deleteItemsSync(filter: Item.createFilter(uuid: uuid), realmData: realmData)
    }
    
    fileprivate func deleteItemsSync(filter: String, realmData: RealmData?) -> Bool {
        return doInWriteTransactionSync(realmData: realmData) {realm -> Bool in
            if let item = realm.objects(Item.self).filter(filter).first {
                _ = DBProv.productProvider.deleteProductsAndDependenciesSync(realm, itemUuid: item.uuid, markForSync: true)
                _ = DBProv.ingredientProvider.deleteIngredientsAndDependenciesSync(realm: realm, itemUuid: item.uuid)
                realm.delete(item)
                return true
                
            } else {
                QL3("Didn't find item with filter: \(filter) to be deleted. Do nothing.")
                return true // Don't see a particular reason to show the user an error here, so we just log a warning and return success.
            }
        } ?? false
    }
    
    // load item and update or create one
    // if we find an item with the unique we update it - this is for the case the user changes category color etc for an existing item while adding it
    // NOTE: This doesn't save anything to the database (no particular reason, except that the current caller of this method does the saving)
    func mergeOrCreateItemSync(itemInput: ItemInput, updateCategory: Bool) -> ProvResult<Item, DatabaseError> {
        
        switch findSync(name: itemInput.name) {
        case .ok(let itemMaybe):
            if let item = itemMaybe {
                if updateCategory {
                    // update non unique properties (we just searched category by unique so it doesn't make sense to update this)
                    item.category.color = itemInput.categoryColor
                }

                return .ok(item)
                
            } else { // item doesn't exist
                
                func onHasCategory(_ category: ProductCategory) -> ProvResult<Item, DatabaseError> { // now we retrieved / created category, create the item with it
                    let newItem = Item(uuid: UUID().uuidString, name: itemInput.name, category: category, fav: 0)
                    return .ok(newItem)
                }
                
                switch DBProv.productCategoryProvider.loadCategoryWithUniqueSync(itemInput.name) {
                    
                case .ok(let categoryMaybe):
                    
                    if let existingCategory = categoryMaybe { // category with unique exists
                        if updateCategory {
                            // update non unique properties (we just searched category by unique so it's not necessary to update this)
                            // TODO repeated code with updateCategory above, when item already exists
                            existingCategory.color = itemInput.categoryColor
                        }
                        return onHasCategory(existingCategory)
                        
                    } else { // category with unique doesn't exist
                        let newCategory = ProductCategory(uuid: UUID().uuidString, name: itemInput.categoryName, color: itemInput.categoryColor)
                        return onHasCategory(newCategory)
                    }

                    
                    
                case .err(let error): return .err(error)
                }
            }
            
        case .err(let error): return .err(error)
        }
    }
    
}
