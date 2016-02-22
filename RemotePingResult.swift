//
//  RemotePingResult.swift
//  shoppin
//
//  Created by ischuetz on 16/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemotePingResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
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
