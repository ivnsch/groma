//
//  RemoteSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


// TODO! server should not send uuid
public struct RemoteSharedUser: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    public let uuid: String
    public var email: String
    public let firstName: String
    public let lastName: String
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let email = representation.value(forKeyPath: "email") as? String,
            let firstName = representation.value(forKeyPath: "firstName") as? String,
            let lastName = representation.value(forKeyPath: "lastName") as? String
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSharedUser]? {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), email: \(email), firstName: \(firstName), lastName: \(lastName)}"
    }
}
