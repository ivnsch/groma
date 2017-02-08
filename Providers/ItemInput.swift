//
//  ItemInput.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import Foundation

public final class ItemInput: CustomDebugStringConvertible {
    
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) name: \(name)}"
    }
}
