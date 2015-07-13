//
//  ListProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListProviderImpl: ListProvider {
   
    func users(list: List, handler: ProviderResult<[SharedUser]> -> ()) {
        // TODO
        let user1 = SharedUser(email: "foo@bar.com", uuid: "uuid1", firstName: "test", lastName: "tester")
        let user2 = SharedUser(email: "bla@bla.de", uuid: "uuid2", firstName: "Ivan", lastName: "Schuetz")
        let result = ProviderResult(status: .Success, sucessResult: [user1, user2])
        
        handler(result)
    }
    
    func addUserToList(list: List, email: String, handler: ProviderResult<SharedUser> -> ()) {
        // TODO
        let addedUser = SharedUser(email: email, uuid: "uuid123", firstName: "added", lastName: "user")
        let result = ProviderResult(status: .Success, sucessResult: addedUser)
        
        handler(result)
    }

}
