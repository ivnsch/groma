//
//  RoundTextField.swift
//  shoppin
//
//  Created by ischuetz on 22/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class RoundTextField: UITextField {
    
    @IBInspectable var fontType: Int = -1

    @IBInspectable var cornerRadius: CGFloat = 15

    fileprivate var originalTextColor: UIColor?
    
    fileprivate var drawInvalid: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
        }
        self.originalTextColor = textColor
    }

    // TODO review - had to be commented while swift 4 migration (extension declaration cannot be overriden)
//    override func showValidationError() {
//        drawInvalid = true
//        setNeedsDisplay()
//    }
//
//    override func clearValidationError() {
//        drawInvalid = false
//        setNeedsDisplay()
//    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        let circlePath = UIBezierPath(roundedRect: rect, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        circlePath.close()
        
        context?.setFillColor(UIColor.white.cgColor)
        context?.addPath(circlePath.cgPath)
        context?.fillPath()
        
        if drawInvalid {
            
            let borderWidth: CGFloat = 1
            let halfBorderWidth = borderWidth / 2
            
            let borderPath = UIBezierPath(roundedRect: rect.insetAll(halfBorderWidth), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            borderPath.close()
            
            context?.setStrokeColor(UIColor.flatRed.cgColor)
            context?.setLineWidth(1)
            context?.addPath(borderPath.cgPath)
            context?.strokePath()
        }
    }
}
