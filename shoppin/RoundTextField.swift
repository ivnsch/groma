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
    
    private var originalTextColor: UIColor?
    
    private var drawInvalid: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFontOfSize(size)
        }
        self.originalTextColor = textColor
    }
    
    override func showValidationError() {
        drawInvalid = true
        setNeedsDisplay()
    }
    
    override func clearValidationError() {
        drawInvalid = false
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRectMake(0, 0, rect.width, rect.height)
        let circlePath = UIBezierPath(roundedRect: rect, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(15, 15))
        circlePath.closePath()
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextAddPath(context, circlePath.CGPath)
        CGContextFillPath(context)
        
        if drawInvalid {
            
            let borderWidth: CGFloat = 1
            let halfBorderWidth = borderWidth / 2
            
            let borderPath = UIBezierPath(roundedRect: rect.insetAll(halfBorderWidth), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(15, 15))
            borderPath.closePath()
            
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            CGContextSetLineWidth(context, 1)
            CGContextAddPath(context, borderPath.CGPath)
            CGContextStrokePath(context)
        }
    }
}
