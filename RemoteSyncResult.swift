//
//  RemoteSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteSyncResult<T: ResponseCollectionSerializable>: ResponseObjectSerializable, CustomDebugStringConvertible {
    let items: [T]
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let items = representation.valueForKeyPath("items") as! [AnyObject]
        self.items = T.collection(response: response, representation: items)

        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
//        self.couldNotUpdate = String.collection(response: response, representation: couldNotUpdate)
        
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
//        self.couldNotDelete = U.collection(response: response, representation: couldNotDelete)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) items: \(self.items), couldNotUpdate: \(self.couldNotUpdate), couldNotDelete: \(self.couldNotDelete)}"
    }
}