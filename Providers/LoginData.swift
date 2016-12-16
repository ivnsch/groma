//
//  LoginData.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO rename logininput
public class LoginData: Equatable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), email: \(self.email), password: \(self.password)}"
    }
}

public func ==(lhs: LoginData, rhs: LoginData) -> Bool {
    return lhs.email == rhs.email
}
