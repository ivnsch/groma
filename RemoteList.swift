//
//  RemoteList.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

final class RemoteList: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let id: String
    let name: String
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.id = representation.valueForKeyPath("id") as! String
        self.name = representation.valueForKeyPath("name") as! String
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
        return "{\(self.dynamicType) id: \(self.id), name: \(self.name)}"
    }
}