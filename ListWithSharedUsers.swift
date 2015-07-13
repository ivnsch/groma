//
//  ListWithSharedUsers.swift
//  shoppin
//
//  Created by ischuetz on 11/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListWithSharedUsersInput {
   
    let list: List
    let users: [SharedUserInput]
    
    init(list: List, users: [SharedUserInput]) {
        self.list = list
        self.users = users
    }
}
