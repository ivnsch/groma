//
//  SocialLoginResult.swift
//  shoppin
//
//  Created by ischuetz on 01/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteSocialLoginResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let token: String
    let email: String
    let firstName: String
    let lastName: String
    
    @objc required init?(representation: AnyObject) {
        self.token = representation.valueForKeyPath("token") as! String
        self.email = representation.valueForKeyPath("email") as! String
        self.firstName = representation.valueForKeyPath("firstName") as! String
        self.lastName = representation.valueForKeyPath("lastName") as! String
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) email: \(self.email), firstName: \(self.firstName)}, lastName: \(self.lastName)}"
    }
}