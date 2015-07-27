//
//  SharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO shared user for client should be only email (and later email+provider), so remove other attributes and remove SharedUserInput
class SharedUser: Equatable {
    let email: String
    
    init(email: String) {
        self.email = email
    }
}

func ==(lhs: SharedUser, rhs: SharedUser) -> Bool {
    return lhs.email == rhs.email
}