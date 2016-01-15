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

    init(_ group: ListItemGroup, boldRange: NSRange? = nil) {
        self.group = group
        super.init(boldRange: boldRange)
    }
    
    override var labelText: String {
        return group.name
    }
    
    override func clearBoldRangeCopy() -> QuickAddGroup {
        return QuickAddGroup(group)
    }
    
    override func same(item: QuickAddItem) -> Bool {
        if let groupItem = item as? QuickAddGroup {
            return group.same(groupItem.group)
        } else {
            return false
        }
    }
}