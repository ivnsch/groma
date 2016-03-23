//
//  UITextField.swift
//  shoppin
//
//  Created by ischuetz on 25/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

private var maxLengthDictionary = [UITextField: Int]()

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
    
    
    @IBInspectable var maxLength: Int {
        get {
            if let length = maxLengthDictionary[self] {
                return length
            } else {
                return Int.max
            }
        }
        set {
            maxLengthDictionary[self] = newValue
            addTarget(self, action: "checkMaxLength:", forControlEvents: UIControlEvents.EditingChanged)
        }
    }
    
    func checkMaxLength(sender: UITextField) {
        if let newText = sender.text {
            if newText.characters.count > maxLength {
                let cursorPosition = selectedTextRange
                text = (newText as NSString).substringWithRange(NSRange(location: 0, length: maxLength))
                selectedTextRange = cursorPosition
            }
        }
    }
    
    func setPlaceholderWithColor(placeholder: String, color: UIColor) {
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSForegroundColorAttributeName: color])
    }
}
