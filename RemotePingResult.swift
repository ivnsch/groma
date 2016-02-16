//
//  RemotePingResult.swift
//  shoppin
//
//  Created by ischuetz on 16/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemotePingResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let token: String
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.token = representation.valueForKeyPath("token") as! String
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) token: \(self.token)}"
    }
}
