//
//  SubmitButtonHeightConstraint.swift
//  groma
//
//  Created by Ivan Schuetz on 24.03.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//
import UIKit

class SubmitButtonHeightConstraint: NSLayoutConstraint {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.constant = DimensionsManager.submitButtonHeight
    }
}
