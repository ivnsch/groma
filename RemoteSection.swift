//
//  RemoteSection.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteSection: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let lastUpdate: NSDate
    
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)
        
        self.todoOrder = representation.valueForKeyPath("todoOrder") as! Int
        self.doneOrder = representation.valueForKeyPath("doneOrder") as! Int
        self.stashOrder = representation.valueForKeyPath("stashOrder") as! Int
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteSection] {
        var sections = [RemoteSection]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteSection(response: response, representation: obj) {
                sections.append(section)
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastUpdate: \(lastUpdate)}"
    }
}

extension RemoteSection {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}