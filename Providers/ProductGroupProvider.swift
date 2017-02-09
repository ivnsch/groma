//
//  ProductGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public enum GroupSortBy {
    case alphabetic, fav, order
}

public protocol ProductGroupProvider {

    // groups
    
    func groups(sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<Results<ProductGroup>>) -> Void)
    
    func groups(_ range: NSRange, sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<[ProductGroup]>) -> Void)

    func groups(_ text: String, range: NSRange, sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<(substring: String?, groups: [ProductGroup])>) -> Void)
    
    func add(_ groups: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func update(_ group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func update(_ groups: [ProductGroup], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func updateGroupsOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func incrementFav(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func remove(_ group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func removeGroup(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // group items

    func groupItems(_ group: ProductGroup, sortBy: InventorySortBy, fetchMode: ProviderFetchModus, _ handler: @escaping (ProviderResult<Results<GroupItem>>) -> Void)
    
    func add(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<GroupItem>) -> Void)

    func add(_ items: [GroupItem], group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    // For websocket - simply upserts the inventory item, does not any checks or re-referencing of dependencies.
    func addOrUpdateLocal(_ groupItems: [GroupItem], _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func addGroupItems(_ srcGroup: ProductGroup, targetGroup: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<[(groupItem: GroupItem, delta: Float)]>) -> Void)

    func add(_ itemInput: GroupItemInput, group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<GroupItem>) -> Void)

    func update(_ input: ListItemInput, updatingGroupItem: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<(groupItem: GroupItem, replaced: Bool)>) -> Void)
    
    // Used by websockets TODO review (compare with update:input)
    func update(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func remove(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeGroupItem(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func increment(_ groupItem: GroupItem, delta: Float, remote: Bool, _ handler: @escaping (ProviderResult<Float>) -> Void)

    func increment(_ increment: ItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<Float>) -> Void)
}
