//
//  QuickAddGroup.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class QuickAddGroup: QuickAddItem {
    
    public let group: ProductGroup

    public init(_ group: ProductGroup, boldRange: NSRange? = nil) {
        self.group = group
        super.init(boldRange: boldRange)
    }
    
    public override var labelText: String {
        return group.name
    }
    
    public override var label2Text: String {
        return ""
    }

    public override var label3Text: String {
        return ""
    }
    
    public override var color: UIColor {
        return group.color
    }
    
    public override func clearBoldRangeCopy() -> QuickAddGroup {
        return QuickAddGroup(group)
    }
    
    public override func same(_ item: QuickAddItem) -> Bool {
        if let groupItem = item as? QuickAddGroup {
            return group.same(groupItem.group)
        } else {
            return false
        }
    }
}
