//
//  Suggestion.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class Suggestion: Equatable, Hashable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) name: \(self.name)}"
    }
    
    public var hashValue: Int {
        return self.name.hashValue
    }
    
}

public func ==(lhs: Suggestion, rhs: Suggestion) -> Bool {
    return lhs.name == rhs.name
}
