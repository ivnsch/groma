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
class QuickAddItem: Identifiable {

    var boldRange: NSRange?
    var textSize: CGSize? = nil
    var didAnimateAlready: Bool = false
    
    init(boldRange: NSRange? = nil) {
        self.boldRange = boldRange
    }
    
    var labelText: String {
        fatalError("Override")
    }
    
    var label2Text: String {
        fatalError("Override")
    }
    
    var label3Text: String {
        fatalError("Override")
    }
    
    var color: UIColor {
        fatalError("Override")
    }
    
    func clearBoldRangeCopy() -> QuickAddItem {
        return QuickAddItem()
    }
    
    func same(item: QuickAddItem) -> Bool {
        fatalError("Override")
    }
}
