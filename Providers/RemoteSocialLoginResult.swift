//
//  SocialLoginResult.swift
//  shoppin
//
//  Created by ischuetz on 01/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSocialLoginResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let token: String
    let email: String
    let firstName: String
    let lastName: String
    let isRegister: Bool
    
    init?(representation: AnyObject) {
        guard
            let token = representation.value(forKeyPath: "token") as? String,
            let email = representation.value(forKeyPath: "email") as? String,
            let firstName = representation.value(forKeyPath: "firstName") as? String,
            let lastName = representation.value(forKeyPath: "lastName") as? String,
            let isRegister = representation.value(forKeyPath: "isRegister") as? Bool
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.token = token
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.isRegister = isRegister
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) email: \(email), firstName: \(firstName)}, lastName: \(lastName), isRegister: \(isRegister)}"
    }
}
