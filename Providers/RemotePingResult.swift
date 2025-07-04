//
//  RemotePingResult.swift
//  shoppin
//
//  Created by ischuetz on 16/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemotePingResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let token: String
    
    init?(representation: AnyObject) {
        guard
            let token = representation.value(forKeyPath: "token") as? String
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.token = token
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) token: \(self.token)}"
    }
}
