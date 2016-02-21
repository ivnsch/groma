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
    
    func remove(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func removeGroup(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    // group items
    
    func groupItems(group: ListItemGroup, _ handler: ProviderResult<[GroupItem]> -> Void)
    
    func add(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func add(items: [GroupItem], group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func addGroupItems(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<[GroupItem]> -> ())

    func add(itemInput: GroupItemInput, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<GroupItem> -> Void)
    
    func update(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func increment(listItem: GroupItem, delta: Int, _ handler: ProviderResult<Any> -> ())

}