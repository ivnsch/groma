//
//  TextFieldHeightConstraint.swift
//  shoppin
//
//  Created by ischuetz on 21/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class TextFieldHeightConstraint: NSLayoutConstraint {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = DimensionsManager.textFieldHeightConstraint
    }
}
