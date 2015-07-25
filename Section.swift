//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class Section: Hashable, ResponseObjectSerializable, ResponseCollectionSerializable {
    let uuid: String
    let name: String
    
    init(uuid:  String, name: String) {
        self.uuid = uuid
        self.name = name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("id") as! String
        self.name = representation.valueForKeyPath("name") as! String
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
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name)}"
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.uuid == rhs.uuid
}
