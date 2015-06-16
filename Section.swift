//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

final class Section: Hashable, ResponseObjectSerializable, ResponseCollectionSerializable {
    let id: String
    let name: String
    
    init(id:  String, name: String) {
        self.id = id
        self.name = name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.id = representation.valueForKeyPath("id") as! String
        self.name = representation.valueForKeyPath("name") as! String
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Section] {
        var sections = [Section]()
        for obj in representation as! [AnyObject] {
            if let section = Section(response: response, representation: obj) {
                sections.append(section)
            }
            
        }
        return sections
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.name == rhs.name
}
