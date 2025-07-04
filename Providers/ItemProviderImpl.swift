//
//  ItemProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import UIKit
import RealmSwift

class ItemProviderImpl: ItemProvider {

    func items(sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<Item>>) -> Void) {
        DBProv.itemProvider.items(sortBy: sortBy) {resultsMaybe in
            if let results = resultsMaybe {
                handler(ProviderResult(status: .success, sucessResult: results))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func items(_ text: String, onlyEdible: Bool, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, items: Results<Item>)>) -> Void) {
        DBProv.itemProvider.items(text, onlyEdible: onlyEdible, range: range, sortBy: sortBy) {(substring: String?, items: Results<Item>?) in
            if let items = items {
                handler(ProviderResult(status: .success, sucessResult: (substring, items)))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func item(name: String, _ handler: @escaping (ProviderResult<Item?>) -> Void) {
        DBProv.itemProvider.find(name: name) {result in
            switch result {
            case .ok(let itemMaybe): handler(ProviderResult(status: .success, sucessResult: itemMaybe))
            case .err(_): handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func items(names: [String], _ handler: @escaping (ProviderResult<Results<Item>>) -> Void) {
        switch DBProv.itemProvider.items(names: names) {
        case .ok(let items): handler(ProviderResult(status: .success, sucessResult: items))
        case .err(_): handler(ProviderResult(status: .databaseUnknown))
        }
    }

    func addOrUpdate(input: ItemInput, _ handler: @escaping (ProviderResult<(Item, Bool)>) -> Void) {
        DBProv.itemProvider.addOrUpdate(input: input) {result in
            if let result = result {
                handler(ProviderResult(status: .success, sucessResult: result))

            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func delete(itemUuid: String, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.itemProvider.delete(uuid: itemUuid, realmData: realmData) {success in
            if success {
                handler(ProviderResult(status: .success))
                
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func delete(itemName: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.itemProvider.delete(name: itemName) {success in
            if success {
                handler(ProviderResult(status: .success))
                
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}
