//
//  UserIdentity.swift
//  shoppin
//
//  Created by ischuetz on 30/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class UserIdentity: Equatable {
    let uuid: String
    let email: String
    
    init(uuid: String, email: String) {
        self.uuid = uuid
        self.email = email
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType), uuid: \(self.uuid), email: \(self.email)}"
    }
}

func ==(lhs: UserIdentity, rhs: UserIdentity) -> Bool {
    return lhs.uuid == rhs.uuid
}