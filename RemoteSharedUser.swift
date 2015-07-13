//
//  RemoteSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteSharedUser: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    
    let uuid: String
    var email: String
    let firstName: String
    let lastName: String
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.email = representation.valueForKeyPath("email") as! String
        self.firstName = representation.valueForKeyPath("firstName") as! String
        self.lastName = representation.valueForKeyPath("lastName") as! String
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteSharedUser] {
        var listItems = [RemoteSharedUser]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteSharedUser(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), email: \(self.email), firstName: \(self.firstName), lastName: \(self.lastName)}"
    }
}
