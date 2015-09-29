//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class Section: Hashable, ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    
    init(uuid:  String, name: String, order: Int) {
        self.uuid = uuid
        self.name = name
        self.order = order
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("id") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.order = representation.valueForKeyPath("order") as! Int
    }
    
    @objc static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Section] {
        var sections = [Section]()
        for obj in representation as! [AnyObject] {
            if let section = Section(response: response, representation: obj) {
                sections.append(section)
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), order: \(self.order)}"
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.uuid == rhs.uuid
}
