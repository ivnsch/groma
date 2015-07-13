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
   
    func users(list: List, handler: ProviderResult<[SharedUser]> -> ())
    
    func addUserToList(list: List, email: String, handler: ProviderResult<SharedUser> -> ())
}
