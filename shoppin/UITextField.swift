//
//  UITextField.swift
//  shoppin
//
//  Created by ischuetz on 25/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension UITextField {

    func showValidationError() {
        self.layer.borderColor = UIColor.redColor().CGColor
        self.layer.borderWidth = 1.0
    }
    
    func clearValidationError() {
        self.layer.borderColor = UIColor.clearColor().CGColor
        self.layer.borderWidth = 0.0
    }
    
    func clear() {
        self.text = ""
    }
}
