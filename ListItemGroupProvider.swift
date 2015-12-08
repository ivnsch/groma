//
//  ListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListItemGroupProvider {

    // groups
    
    func groups(handler: ProviderResult<[ListItemGroup]> -> Void)
    
    func groups(range: NSRange, _ handler: ProviderResult<[ListItemGroup]> -> Void)

    func groupsContainingText(text: String, _ handler: ProviderResult<[ListItemGroup]> -> Void)
    
    func add(groups: ListItemGroup, _ handler: ProviderResult<Any> -> Void)
    
    func update(group: ListItemGroup, _ handler: ProviderResult<Any> -> Void)

    func remove(group: ListItemGroup, _ handler: ProviderResult<Any> -> Void)

    // group items
    
    func groupItems(group: ListItemGroup, handler: ProviderResult<[GroupItem]> -> Void)
    
    func update(item: GroupItem, group: ListItemGroup, _ handler: ProviderResult<Any> -> ())
    
    func remove(item: GroupItem, _ handler: ProviderResult<Any> -> Void)
}