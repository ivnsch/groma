//
//  RoundTextField.swift
//  shoppin
//
//  Created by ischuetz on 22/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class RoundTextField: UITextField {
    
    @IBInspectable var fontType: Int = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFontOfSize(size)
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let circlePath = UIBezierPath(roundedRect: CGRectMake(0, 0, rect.width, rect.height), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(15, 15))
        circlePath.closePath()
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextAddPath(context, circlePath.CGPath)
        CGContextFillPath(context)
    }
}
