//
//  RemoteRegisterResult.swift
//  shoppin
//
//  Created by ischuetz on 13/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteRegisterResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
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
