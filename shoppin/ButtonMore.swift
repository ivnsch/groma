//
//  ButtonMore.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// UIButton with utilities
class ButtonMore: UIButton {

    @IBInspectable var fontType: Int = -1
    
    var currentSelectedTintColor: UIColor?
    
    let selectedTintColor: UIColor = UIColor.darkGrayColor()
    let normalTintColor: UIColor = UIColor.lightGrayColor()
    
    override var highlighted: Bool {
        get {
            return super.highlighted
        }
        set {
            if newValue {
                imageView?.tintColor = selectedTintColor
                tintColor = selectedTintColor
            } else {
                if let currentSelectedTintColor = currentSelectedTintColor {
                    imageView?.tintColor = currentSelectedTintColor
                    tintColor = currentSelectedTintColor
                } else {
                    imageView?.tintColor = normalTintColor
                    tintColor = normalTintColor
                }
            }
            super.highlighted = newValue
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            if newValue {
                imageView?.tintColor = selectedTintColor
                tintColor = selectedTintColor
                currentSelectedTintColor = selectedTintColor
            } else {
                imageView?.tintColor = normalTintColor
                tintColor = normalTintColor
                currentSelectedTintColor = nil
            }
            super.selected = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let size = LabelMore.mapToFontSize(fontType) {
            self.titleLabel?.font = UIFont.systemFontOfSize(size)
        }
    }
}
