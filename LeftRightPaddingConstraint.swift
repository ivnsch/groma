//
//  LeftRightPaddingConstraint.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class LeftRightPaddingConstraint: NSLayoutConstraint {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = DimensionsManager.leftRightPaddingConstraint
    }
}
