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
        
        load(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)) {(items: Results<Item>?) in
            handler(items)
        }
    }
    
    func find(name: String, _ handler: @escaping (ProvResult<Item?, DatabaseError>) -> Void) {
        handler(findSync(name: name))
    }
    
    func addOrUpdate(input: ItemInput, _ handler: @escaping (Bool) -> Void) {
        handler(addOrUpdateSync(input: input))
    }
    
    func delete(uuid: String, handler: @escaping (Bool) -> Void) {
        handler(deleteSync(uuid: uuid))
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
    
    func addOrUpdateSync(input: ItemInput) -> Bool {
        let existingItemMaybe = findSync(name: input.name)
        
        if existingItemMaybe.isOk {
            QL1("Item already exists")
            // There's nothing to update now so we just return true
            return true
            
        } else {
            let writeSuccess: Bool? = self.doInWriteTransactionSync({realm in
                let item = Item(uuid: UUID().uuidString, name: input.name, fav: 0)
                realm.add(item, update: true)
                return true
            })
            
            return writeSuccess ?? false
            
        }
    }
    
    func deleteSync(name: String) -> Bool {
        return withRealmSync({realm -> Bool in
            realm.delete(realm.objects(Item.self).filter(Item.createFilter(name: name)))
            return true
        }) ?? false
    }
    
    func deleteSync(uuid: String) -> Bool {
        return withRealmSync({realm -> Bool in
            realm.delete(realm.objects(Item.self).filter(Item.createFilter(uuid: uuid)))
            return true
        }) ?? false
    }
    
}
