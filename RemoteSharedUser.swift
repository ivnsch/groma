//
//  RemoteSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSharedUser: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    var email: String
    let firstName: String
    let lastName: String
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let email = representation.valueForKeyPath("email") as? String,
            let firstName = representation.valueForKeyPath("firstName") as? String,
            let lastName = representation.valueForKeyPath("lastName") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
    
    static func collection(representation: AnyObject) -> [RemoteSharedUser]? {
        var listItems = [RemoteSharedUser]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteSharedUser(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), email: \(email), firstName: \(firstName), lastName: \(lastName)}"
    }
}
