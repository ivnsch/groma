//
//  Array_Inventory.swift
//  shoppin
//
//  Created by ischuetz on 26/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: Inventory {
    
    func sortedByOrder() -> [Inventory] {
        return sort {$0.order < $1.order}
    }
}