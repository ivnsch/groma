//
//  QuickAddItem.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO check if this makes sense, if not remove
// maybe we can use directly Product and ProductGroup in table view - so we don't have to call map?
public class QuickAddItem: Identifiable {

    public var boldRange: NSRange?
    public var textSize: CGSize? = nil // cache
    public var didAnimateAlready: Bool = false

    public init() {}
    
    public init(boldRange: NSRange? = nil) {
        self.boldRange = boldRange
    }
    
    public var labelText: String {
        fatalError("Override")
    }
    
    public var label2Text: String {
        fatalError("Override")
    }
    
    public var label3Text: String {
        fatalError("Override")
    }

    public var color: UIColor {
        fatalError("Override")
    }
    
    public func clearBoldRangeCopy() -> QuickAddItem {
        return QuickAddItem()
    }
    
    public func same(_ item: QuickAddItem) -> Bool {
        fatalError("Override")
    }
}
