//
//  QuickAddGroup.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class QuickAddGroup: QuickAddItem {
    
    let group: ListItemGroup
    
    init(_ group: ListItemGroup) {
        self.group = group
    }
    
    override var labelText: String {
        return group.name
    }
}