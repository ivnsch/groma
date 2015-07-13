//
//  SharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SharedUser: Equatable {
    let email: String
    let uuid: String
    let firstName: String
    let lastName: String
    
    init(email: String, uuid: String, firstName: String, lastName: String) {
        self.email = email
        self.uuid = uuid
        self.firstName = firstName
        self.lastName = lastName
    }
    
    convenience init(user: User) {
        self.init(email: user.email, uuid: user.uuid, firstName: user.firstName, lastName: user.lastName)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType), email: \(self.email), uuid: \(self.uuid), firstName: \(self.firstName), lastName: \(self.lastName)}"
    }
}

func ==(lhs: SharedUser, rhs: SharedUser) -> Bool {
    return lhs.email == rhs.email
}