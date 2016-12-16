//
//  UserInput.swift
//  shoppin
//
//  Created by ischuetz on 10/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class UserInput {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    
    public init(email: String, password: String, firstName: String, lastName: String) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), email: \(self.email), password: \(self.password), firstName: \(self.firstName), lastName: \(self.lastName)}"
    }
}
