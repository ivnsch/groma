//
//  RemoteList.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteList: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let uuid: String
    let name: String
    let users: [RemoteSharedUser]
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let list: AnyObject = representation.valueForKeyPath("list")!
        self.uuid = list.valueForKeyPath("uuid") as! String
        self.name = list.valueForKeyPath("name") as! String
        let unserializedUsers: AnyObject = representation.valueForKeyPath("users")!
        self.users = RemoteSharedUser.collection(response: response, representation: unserializedUsers)
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteList] {
        var lists = [RemoteList]()
        for obj in representation as! [AnyObject] {
            if let list = RemoteList(response: response, representation: obj) {
                lists.append(list)
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), users: \(self.users)}"
    }
}