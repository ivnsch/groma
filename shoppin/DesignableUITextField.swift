//
//  DesignableUITextField.swift
//  groma
//
//  Created by Ivan Schuetz on 28.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

// Src: https://stackoverflow.com/a/41151566/930450 (modified - merged with LineTextView)
@IBDesignable
class DesignableUITextField: UITextField {

    // Provides left padding for images
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftPadding
        return textRect
    }

    @IBInspectable var leftImage: UIImage? {
        didSet {
            updateView()
        }
    }

    @IBInspectable var leftPadding: CGFloat = 0

    @IBInspectable var color: UIColor = Theme.lightGrey2 {
        didSet {
            updateView()
        }
    }

    @IBInspectable var fontType: Int = -1

    fileprivate let lineWidth: CGFloat = 1

    @IBInspectable var isLine: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
        }
    }

    func updateView() {
        if let image = leftImage {
            leftViewMode = UITextFieldViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            // Note: In order for your image to use the tint color, you have to select the image in the Assets.xcassets and change the "Render As" property to "Template Image".
            imageView.tintColor = color
            leftView = imageView
        } else {
            leftViewMode = UITextFieldViewMode.never
            leftView = nil
        }

        // Placeholder text color
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ?  placeholder! : "", attributes:[NSAttributedStringKey.foregroundColor: color])

        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        if isLine {
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(color.cgColor)

            let y = frame.height - lineWidth
            context?.setLineWidth(lineWidth)
            context?.move(to: CGPoint(x: 0, y: y))
            context?.addLine(to: CGPoint(x: frame.width, y: y))
            context?.drawPath(using: .stroke)
        }
    }
}
