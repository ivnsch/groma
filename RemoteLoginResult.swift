//
//  RemoteLoginResult.swift
//  shoppin
//
//  Created by ischuetz on 03/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteLoginResult: ResponseObjectSerializable, CustomDebugStringConvertible {
   
    let token: String
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.token = representation.valueForKeyPath("token") as! String
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) token: \(self.token)}"
    }
}
