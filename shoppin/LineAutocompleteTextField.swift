//
//  LineAutocompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class LineAutocompleteTextField: MyAutoCompleteTextField {

    fileprivate let lineWidth: CGFloat = 1
    
    fileprivate static let defaultLineColor = UIColor.gray
    fileprivate var lineColor = defaultLineColor
    
    override func showValidationError() {
        lineColor = UIColor.flatRed
        setNeedsDisplay()
    }
    
    override func clearValidationError() {
        lineColor = LineAutocompleteTextField.defaultLineColor
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(lineColor.cgColor)
        
        let y = frame.height - lineWidth
        context?.setLineWidth(lineWidth)
        context?.move(to: CGPoint(x: 0, y: y))
        context?.addLine(to: CGPoint(x: frame.width, y: y))
        context?.drawPath(using: .stroke)
    }
}
