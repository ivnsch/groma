//
//  RemoteLoginResult.swift
//  shoppin
//
//  Created by ischuetz on 03/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteLoginResult: ResponseObjectSerializable, CustomDebugStringConvertible {
   
    let token: String
    
    init?(representation: AnyObject) {
        guard
            let token = representation.valueForKeyPath("token") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.token = token
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) token: \(self.token)}"
    }
}
