//
//  TextFieldMore.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class TextFieldMore: UITextField {
    
    @IBInspectable var fontType: Int = -1
    
    var calculateIntrinsicSizeManually: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
        }
    }
    
    // Invalidate intrinsic size while typing doesn't work (field doesn't change its width) so we need this. See also http://stackoverflow.com/questions/18236661/resize-a-uitextfield-while-typing-by-using-autolayout
    override var intrinsicContentSize: CGSize {
        
        if calculateIntrinsicSizeManually {
            
            if let font = font {
                
                return text.map{
                    let textSize = $0.size(font)
                    return CGSize(width: textSize.width + 2, height: textSize.height) // + 2 "magic number" for some reason sometimes the label gets truncated (e.g. when we change the quantity with swiping - at some numbers. With + 2 it doesn't happen
                } ?? CGSize.zero
                
            } else {
                return CGSize.zero
            }
        } else {
            return super.intrinsicContentSize
        }
     }
}
