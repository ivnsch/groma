//
//  QuickAddItem.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO check if this makes sense, if not remove
// maybe we can use directly Product and ListItemGroup in table view - so we don't have to call map?
class QuickAddItem {

    var boldRange: NSRange?
    var textSize: CGSize? = nil
    var didAnimateAlready: Bool = false
    
    init(boldRange: NSRange? = nil) {
        self.boldRange = boldRange
    }
    
    var labelText: String {
        fatalError("Override")
    }
    
    func clearBoldRangeCopy() -> QuickAddItem {
        return QuickAddItem()
    }
}
