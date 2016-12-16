//
//  RoundTextField.swift
//  shoppin
//
//  Created by ischuetz on 22/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class RoundTextField: UITextField {
    
    @IBInspectable var fontType: Int = -1
    
    fileprivate var originalTextColor: UIColor?
    
    fileprivate var drawInvalid: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
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
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        let circlePath = UIBezierPath(roundedRect: rect, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 15, height: 15))
        circlePath.close()
        
        context?.setFillColor(UIColor.white.cgColor)
        context?.addPath(circlePath.cgPath)
        context?.fillPath()
        
        if drawInvalid {
            
            let borderWidth: CGFloat = 1
            let halfBorderWidth = borderWidth / 2
            
            let borderPath = UIBezierPath(roundedRect: rect.insetAll(halfBorderWidth), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 15, height: 15))
            borderPath.close()
            
            context?.setStrokeColor(UIColor.flatRed.cgColor)
            context?.setLineWidth(1)
            context?.addPath(borderPath.cgPath)
            context?.strokePath()
        }
    }
}
