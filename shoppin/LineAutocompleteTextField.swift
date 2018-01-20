//
//  LineAutocompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

@IBDesignable
class LineAutocompleteTextField: MyAutoCompleteTextField, UITextFieldDelegate {

    fileprivate let lineWidth: CGFloat = 1
    
    fileprivate static let defaultLineColor = Theme.lightGrey2

    @IBInspectable
    var lineColor = defaultLineColor

    var onBeginEditing: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
    }

    // TODO review - had to be commented while swift 4 migration (extension declaration cannot be overriden)
//    override func showValidationError() {
//        lineColor = UIColor.flatRed
//        setNeedsDisplay()
//    }
//
//    override func clearValidationError() {
//        lineColor = LineAutocompleteTextField.defaultLineColor
//        setNeedsDisplay()
//    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(lineColor.cgColor)
        
        let y = frame.height - lineWidth
        context?.setLineWidth(lineWidth)
        context?.move(to: CGPoint(x: 0, y: y))
        context?.addLine(to: CGPoint(x: frame.width, y: y))
        context?.drawPath(using: .stroke)
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }
}
