//
//  ListProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public protocol ListProvider {
    
    func lists(_ remote: Bool, _ handler: @escaping (ProviderResult<Results<List>>) -> ())
    
    func list(_ listUuid: String, _ handler: @escaping (ProviderResult<List>) -> ())
  
    // TODO move list-only methods from listitemsprovider here

    func add(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<List>) -> ())

    func update(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func update(_ lists: [List], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func updateListsOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func remove(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func remove(_ listUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func acceptInvitation(_ invitation: RemoteListInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func rejectInvitation(_ invitation: RemoteListInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void)
}
