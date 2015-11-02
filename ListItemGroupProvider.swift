//
//  ListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListItemGroupProvider {

    func add(groups: [ListItemGroup], _ handler: ProviderResult<Any> -> Void)
    
    func update(group: ListItemGroup, _ handler: ProviderResult<Any> -> Void)

    func groups(handler: ProviderResult<[ListItemGroup]> -> Void)

    func groups(range: NSRange, _ handler: ProviderResult<[ListItemGroup]> -> Void)

    func groupsContainingText(text: String, _ handler: ProviderResult<[ListItemGroup]> -> Void)
    
    func groupItems(group: ListItemGroup, handler: ProviderResult<[GroupItem]> -> Void)

    func remove(group: ListItemGroup, _ handler: ProviderResult<Any> -> Void)

    func add(itemInput: GroupItemInput, group: ListItemGroup, order orderMaybe: Int?, possibleNewSectionOrder: Int?, list: List, _ handler: ProviderResult<GroupItem> -> ())
    
    func add(groupItems: [GroupItem], _ handler: ProviderResult<Any> -> Void)

    func update(items: [GroupItem], _ handler: ProviderResult<Any> -> ())
}