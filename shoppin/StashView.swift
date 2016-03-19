//
//  StashView.swift
//  shoppin
//
//  Created by ischuetz on 03/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class StashView: UIView {
    
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quantityLabel: UILabel!

    var bgColor: UIColor?
    
    var quantity: Int = 0 {
        didSet {
            quantityLabel.text = String(quantity)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgroundColor = UIColor.clearColor()
    }
    
    // this is to draw arrow shape on the right side - for now disabled
//    override func drawRect(rect: CGRect) {
//        let ctx = UIGraphicsGetCurrentContext()
//        CGContextSetFillColorWithColor(ctx, bgColor?.CGColor ?? UIColor.whiteColor().colorWithAlphaComponent(0.3).CGColor)
//        CGContextBeginPath(ctx)
//        CGContextAddPath(ctx, Shapes.arrowToRightBGPath(bounds.size, arrowWidth: 20))
//        CGContextDrawPath(ctx, CGPathDrawingMode.Fill)
//    }
    
    func setOpen(open: Bool) {
        rightConstraint.constant = open ? 0 : 80
        UIView.animateWithDuration(0.5) {[weak self] in
            self?.layoutIfNeeded()
        }
    }
    
    func setTextColor(color: UIColor) {
        quantityLabel.textColor = color
    }
}