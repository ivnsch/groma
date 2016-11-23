//
//  RemoteSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

// TODO! server should not send uuid
struct RemoteSharedUser: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    var email: String
    let firstName: String
    let lastName: String
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let email = representation.value(forKeyPath: "email") as? String,
            let firstName = representation.value(forKeyPath: "firstName") as? String,
            let lastName = representation.value(forKeyPath: "lastName") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteSharedUser]? {
        var listItems = [RemoteSharedUser]()
        for obj in representation {
            if let listItem = RemoteSharedUser(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), email: \(email), firstName: \(firstName), lastName: \(lastName)}"
    }
}
