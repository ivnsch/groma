//
//  ListInput.swift
//  Providers
//
//  Created by Ivan Schuetz on 05/02/2017.
//
//

import Foundation

public struct ListInput {
    
    public let name: String
    public let color: UIColor
    public let store: String
    public let inventory: DBInventory
    
    public init(name: String, color: UIColor, store: String, inventory: DBInventory) {
        self.name = name
        self.color = color
        self.store = store
        self.inventory = inventory
    }
}
