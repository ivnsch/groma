//
//  LeftRightBigPaddingConstraint.swift
//  shoppin
//
//  Created by ischuetz on 22/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class LeftRightBigPaddingConstraint: NSLayoutConstraint {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = DimensionsManager.leftRightBigPaddingConstraint
    }
}
