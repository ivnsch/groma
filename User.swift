//
//  User.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class User: Equatable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    
    init(email: String, password: String, firstName: String, lastName: String) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType), email: \(self.email), password: \(self.password), firstName: \(self.firstName), lastName: \(self.lastName)}"
    }
}

func ==(lhs: User, rhs: User) -> Bool {
    return lhs.email == rhs.email
}