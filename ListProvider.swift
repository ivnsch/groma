//
//  ListProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListProvider {
    
    func lists(remote: Bool, _ handler: ProviderResult<[List]> -> ())
    
    func list(listId: String, _ handler: ProviderResult<List> -> ())
  
    // TODO move list-only methods from listitemsprovider here

    func add(list: List, remote: Bool, _ handler: ProviderResult<List> -> ())

    func update(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func update(lists: [List], remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func syncListsWithListItems(handler: (ProviderResult<[Any]> -> ()))
}