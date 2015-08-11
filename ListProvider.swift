//
//  ListProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol ListProvider {
    
    // TODO move list-only methods from listitemsprovider here

    func add(list: List, _ handler: ProviderResult<List> -> ())

    func update(listInput: List, _ handler: ProviderResult<List> -> ())
    
    func users(list: List, _ handler: ProviderResult<[SharedUser]> -> ())
    
    func addUserToList(list: List, email: String, _ handler: ProviderResult<SharedUser> -> ())
    
    func syncListsWithListItems(handler: (ProviderResult<[Any]> -> ()))
}
