//
//  ListItemGroupProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemGroupProviderImpl: ListItemGroupProvider {

    let dbGroupsProvider = RealmListItemGroupProvider()
    
    func add(groups: [ListItemGroup], _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(groups) {saved in
            if saved {
                handler(ProviderResult(status: .Success))
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    // TODO remove
    func groups(handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groups {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }

    func groups(range: NSRange, _ handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groups(range) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }

    func groupsContainingText(text: String, _ handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groupsContainingText(text) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }
    
    func groupItems(group: ListItemGroup, handler: ProviderResult<[GroupItem]> -> Void) {
        dbGroupsProvider.groupItems(group) {items in
            handler(ProviderResult(status: .Success, sucessResult: items))
        }
    }
    
    func remove(group: ListItemGroup, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.remove(group) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
        }
    }
    
    // TODO it should not be necessary to pass list here
    func add(itemInput: GroupItemInput, group: ListItemGroup, order orderMaybe: Int? = nil, possibleNewSectionOrder: Int?, list: List, _ handler: ProviderResult<GroupItem> -> ()) {

        // TODO! remove? commented because of product update with base quantity and unit, would have to update GroupItemInput but it doesn't seem to be used anymore?
        // TODO review this as part of removal of old groups controllers
//        Providers.productProvider.mergeOrCreateProduct(itemInput.name, productPrice: itemInput.price, category: itemInput.category) {[weak self] result in
//            
//            if let product = result.sucessResult {
//
//                let groupItem = GroupItem(uuid: NSUUID().UUIDString, quantity: itemInput.quantity, product: product)
//                
//                self?.add(groupItem, {result in
//                    if result.success {
//                        handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: groupItem))
//                    } else {
//                        handler(ProviderResult(status: result.status))
//                    }
//                })
//                
//            } else {
//                print("Error fetching product: \(result.status)")
//                handler(ProviderResult(status: .DatabaseUnknown))
//            }
//        }
    }

    func add(groupItems: [GroupItem], _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(groupItems) {saved in
            if saved {
                handler(ProviderResult(status: .Success))
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func add(groupItem: GroupItem, _ handler: ProviderResult<Any> -> Void) {
        add([groupItem], handler)
    }
    
    func update(items: [GroupItem], _ handler: ProviderResult<Any> -> ()) {
        print("TODO")
    }
    
    func update(group: ListItemGroup, _ handler: ProviderResult<Any> -> ()) {
        dbGroupsProvider.update([group]) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))
        }
    }
}