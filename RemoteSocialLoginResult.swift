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
            let token = representation.valueForKeyPath("token") as? String,
            let email = representation.valueForKeyPath("email") as? String,
            let firstName = representation.valueForKeyPath("firstName") as? String,
            let lastName = representation.valueForKeyPath("lastName") as? String,
            let isRegister = representation.valueForKeyPath("isRegister") as? Bool
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
        return "{\(self.dynamicType) email: \(email), firstName: \(firstName)}, lastName: \(lastName), isRegister: \(isRegister)}"
    }
}