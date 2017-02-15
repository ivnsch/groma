//
//  ItemProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import UIKit
import RealmSwift

public protocol ItemProvider {

    func items(sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<Item>>) -> Void)

    func items(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, items: Results<Item>)>) -> Void)

    func item(name: String, _ handler: @escaping (ProviderResult<Item?>) -> Void)

    func addOrUpdate(input: ItemInput, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(itemUuid: String, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(itemName: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
