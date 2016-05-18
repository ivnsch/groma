//
//  TopEmptyViewConstraint.swift
//  shoppin
//
//  Created by ischuetz on 18/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

// we should use a custom view for the empty view instead of repeating it everywhere (TODO), for now this is quicker
class TopEmptyViewConstraint: NSLayoutConstraint {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = DimensionsManager.emptyViewTopConstraint
    }
}
