//
//  ButtonMore.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

// UIButton with utilities
class ButtonMore: UIButton {

    @IBInspectable var fontType: Int = -1
    
    var currentSelectedTintColor: UIColor?
    
    let selectedTintColor: UIColor = UIColor.darkGray
    let normalTintColor: UIColor = UIColor.lightGray
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
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
            super.isHighlighted = newValue
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
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
            super.isSelected = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let size = LabelMore.mapToFontSize(fontType) {
            if let label = self.titleLabel {
                label.font = {
                    if label.font.isBold {
                        return UIFont.boldSystemFont(ofSize: size)
                    } else {
                        return UIFont.systemFont(ofSize: size)
                    }
                }()
            } else {
                logger.w("No label?")
            }
        }
    }
}
