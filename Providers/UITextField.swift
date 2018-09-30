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
            addTarget(self, action: #selector(UITextField.checkMaxLength(_:)), for: UIControl.Event.editingChanged)
        }
    }
    
    @objc public func checkMaxLength(_ sender: UITextField) {
        if let newText = sender.text {
            if newText.count > maxLength {
                let cursorPosition = selectedTextRange
                text = (newText as NSString).substring(with: NSRange(location: 0, length: maxLength))
                selectedTextRange = cursorPosition
            }
        }
    }
    
    public func setPlaceholderWithColor(_ placeholder: String, color: UIColor) {
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: color])
    }

    public var cursorPosition: Int? {
        if let selectedRange = selectedTextRange {
            return offset(from: beginningOfDocument, to: selectedRange.start)
        } else {
            return nil
        }
    }

    public func moveCursor(to: Int) {
        if let newPosition = position(from: beginningOfDocument, offset: to) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}
