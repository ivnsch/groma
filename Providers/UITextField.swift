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

    open func showValidationError() {
        // override
    }
    
    open func clearValidationError() {
        // override
    }
    
    public func clear() {
        self.text = ""
    }
    
    public var trimmedText: String? {
        return self.text.map{$0.trim()}
    }
    
    public var optText: String? {
        if let text = text {
            return text == "" ? nil : text
        } else {
            return nil
        }
    }
    
    @IBInspectable public var maxLength: Int {
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
    
    @objc public func checkMaxLength(_ sender: UITextField) {
        if let newText = sender.text {
            if newText.characters.count > maxLength {
                let cursorPosition = selectedTextRange
                text = (newText as NSString).substring(with: NSRange(location: 0, length: maxLength))
                selectedTextRange = cursorPosition
            }
        }
    }
    
    public func setPlaceholderWithColor(_ placeholder: String, color: UIColor) {
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedStringKey.foregroundColor: color])
    }
}
