//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class Section: Hashable {
    let name:String
    
    init(name:String) {
        self.name = name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.name == rhs.name
}
