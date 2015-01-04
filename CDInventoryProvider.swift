//
//  CDInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import CoreData

class CDInventoryProvider: CDProvider {
    
    func loadInventory() -> [CDInventoryItem] {
        return self.load(entityName: "CDInventoryItem", type: CDInventoryItem.self)
    }
}