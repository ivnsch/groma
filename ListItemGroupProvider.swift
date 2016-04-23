//
//  ListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum GroupSortBy {
    case Alphabetic, Fav, Order
}

protocol ListItemGroupProvider {

    // groups
    
    func groups(handler: ProviderResult<[ListItemGroup]> -> Void)
    
    func groups(range: NSRange, sortBy: GroupSortBy, _ handler: ProviderResult<[ListItemGroup]> -> Void)

    func groups(text: String, range: NSRange, sortBy: GroupSortBy, _ handler: ProviderResult<(substring: String?, groups: [ListItemGroup])> -> Void)
    
    func add(groups: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func update(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func update(groups: [ListItemGroup], remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func updateGroupsOrder(orderUpdates: [OrderUpdate], remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func incrementFav(productUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func remove(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func removeGroup(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    // group items
    
    func groupItems(group: ListItemGroup, sortBy: InventorySortBy, _ handler: ProviderResult<[GroupItem]> -> Void)
    
    func add(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func add(items: [GroupItem], group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func addGroupItems(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<[GroupItem]> -> ())

    func add(itemInput: GroupItemInput, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<GroupItem> -> Void)

    func update(input: ListItemInput, updatingGroupItem: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    // Used by websockets TODO review (compare with update:input)
    func update(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func removeGroupItem(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func increment(groupItem: GroupItem, delta: Int, remote: Bool, _ handler: ProviderResult<Int> -> Void)

    func increment(increment: ItemIncrement, remote: Bool, _ handler: ProviderResult<Int> -> Void)
}