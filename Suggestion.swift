//
//  Suggestion.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class Suggestion: Equatable, Hashable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(self.name)}"
    }
    
    var hashValue: Int {
        return self.name.hashValue
    }
    
}

func ==(lhs: Suggestion, rhs: Suggestion) -> Bool {
    return lhs.name == rhs.name
}