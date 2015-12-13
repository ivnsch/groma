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
    let remoteGroupsProvider = RemoteGroupsProvider()

    
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

    func add(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(group) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))

            if saved && remote {
                self?.remoteGroupsProvider.addGroup(group) {remoteResult in
                    if !remoteResult.success {
                        print("Error: adding group in remote: \(group), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func update(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbGroupsProvider.update(group) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))
            
            if saved && remote {
                self?.remoteGroupsProvider.updateGroup(group) {remoteResult in
                    if !remoteResult.success {
                        print("Error: updating group in remote: \(group), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func remove(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.remove(group) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if saved && remote {
                self?.remoteGroupsProvider.removeGroup(group) {remoteResult in
                    if !remoteResult.success {
                        print("Error: removing group in remote: \(group), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func groupItems(group: ListItemGroup, handler: ProviderResult<[GroupItem]> -> Void) {
        dbGroupsProvider.groupItems(group) {items in
            handler(ProviderResult(status: .Success, sucessResult: items))
        }
    }
    
    func add(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.addGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: adding group item in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func update(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbGroupsProvider.update(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.updateGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: updating group item in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func remove(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.remove(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.removeGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: removeGroupItem in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
}