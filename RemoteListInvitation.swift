//
//  RemoteListInvitation.swift
//  shoppin
//
//  Created by ischuetz on 24/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListInvitation: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let sender: String // TODO send shared user obj not simply email
    let list: RemoteListNoUsers
    
    init?(representation: AnyObject) {
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
    
    static func collection(_ representation: [AnyObject]) -> [RemoteListInvitation]? {
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
    
    var debugDescription: String {
        return "{\(type(of: self)) sender: \(sender), list: \(list)}"
    }
}
