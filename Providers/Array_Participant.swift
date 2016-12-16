//
//  Array_Participant.swift
//  shoppin
//
//  Created by ischuetz on 24/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array where Element: DBSharedUser {
    
    public func containsMe() -> Bool {
        if let myEmail = Prov.userProvider.mySharedUser?.email {
            return self.contains{$0.email == myEmail}
        } else {
            return false
        }
    }
}
