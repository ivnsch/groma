//
//  UserIdentity.swift
//  shoppin
//
//  Created by ischuetz on 30/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class UserIdentity: Equatable {
    public let uuid: String
    public let email: String
    
    public init(uuid: String, email: String) {
        self.uuid = uuid
        self.email = email
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), uuid: \(self.uuid), email: \(self.email)}"
    }
}

public func ==(lhs: UserIdentity, rhs: UserIdentity) -> Bool {
    return lhs.uuid == rhs.uuid
}
