//
//  LoginData.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO rename logininput
class LoginData: Equatable {
    let email: String
    let password: String
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    var debugDescription: String {
        return "{\(type(of: self)), email: \(self.email), password: \(self.password)}"
    }
}

func ==(lhs: LoginData, rhs: LoginData) -> Bool {
    return lhs.email == rhs.email
}
