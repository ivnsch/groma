//
//  InventoryInput.swift
//  Providers
//
//  Created by Ivan Schuetz on 06/02/2017.
//
//

import Foundation

public struct InventoryInput {
    
    public let name: String
    public let color: UIColor
    
    public init(name: String, color: UIColor) {
        self.name = name
        self.color = color
    }
}
