//
//  LineTextField.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class LineTextField: UITextField, ValidatableTextField {

    @IBInspectable var fontType: Int = -1
    
    fileprivate let lineWidth: CGFloat = 1
    
    fileprivate static let defaultLineColor = Theme.lightGrey2

    @IBInspectable
    var lineColor: UIColor = defaultLineColor {
        didSet {
            setNeedsDisplay()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
        }
    }

    func showValidationError() {
        lineColor = UIColor.flatRed
        setNeedsDisplay()
    }

    func clearValidationError() {
        lineColor = LineTextField.defaultLineColor
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
