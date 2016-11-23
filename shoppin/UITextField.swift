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
        // override
    }
    
    func clearValidationError() {
        // override
    }
    
    func clear() {
        self.text = ""
    }
    
    var trimmedText: String? {
        return self.text.map{$0.trim()}
    }
    
    var optText: String? {
        if let text = text {
            return text == "" ? nil : text
        } else {
            return nil
        }
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
            addTarget(self, action: #selector(UITextField.checkMaxLength(_:)), for: UIControlEvents.editingChanged)
        }
    }
    
    func checkMaxLength(_ sender: UITextField) {
        if let newText = sender.text {
            if newText.characters.count > maxLength {
                let cursorPosition = selectedTextRange
                text = (newText as NSString).substring(with: NSRange(location: 0, length: maxLength))
                selectedTextRange = cursorPosition
            }
        }
    }
    
    func setPlaceholderWithColor(_ placeholder: String, color: UIColor) {
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSForegroundColorAttributeName: color])
    }
}
