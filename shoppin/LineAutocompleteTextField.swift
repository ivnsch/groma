//
//  LineAutocompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class LineAutocompleteTextField: MLPAutoCompleteTextField {

    private let lineWidth: CGFloat = 1
    private let lineColor = UIColor.grayColor()
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
        
        let y = frame.height - lineWidth
        CGContextSetLineWidth(context, lineWidth)
        CGContextMoveToPoint(context, 0, y)
        CGContextAddLineToPoint(context, frame.width, y)
        CGContextDrawPath(context, .Stroke)
    }
}
