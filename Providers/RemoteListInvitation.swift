//
//  RemoteListInvitation.swift
//  shoppin
//
//  Created by ischuetz on 24/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteListInvitation: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let sender: String // TODO send shared user obj not simply email
    public let list: RemoteListNoUsers
    
    public init?(representation: AnyObject) {
        guard
            let sender = representation.value(forKeyPath: "sender") as? String,
            let itemObj = representation.value(forKeyPath: "item"),
            let list = RemoteListNoUsers(representation: itemObj as AnyObject)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.sender = sender
        self.list = list
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteListInvitation]? {
        var lists = [RemoteListInvitation]()
        for obj in representation {
            if let list = RemoteListInvitation(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) sender: \(sender), list: \(list)}"
    }
}
