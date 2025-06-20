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
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    var originalHeight: CGFloat = 0

    @IBOutlet weak var button: UIButton!
    
    var bgColor: UIColor?
    
    fileprivate var expanded: Bool = true // if vertically minimized or expanded (expanded is normal size)

    var quantity: Float = 0 {
        didSet {
//            quantityLabel.text = String(quantity)
            button.tintColor = quantity > 0 ? UIColor.white : UIColor(hexString: "3FCF9C")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgroundColor = UIColor.clearColor()
        originalHeight = DimensionsManager.listItemsPricesViewHeight
        clipsToBounds = true
        
        setExpandedVertical(false, animated: false)
    }
    
    // this is to draw arrow shape on the right side - for now disabled
//    override func drawRect(rect: CGRect) {
//        let ctx = UIGraphicsGetCurrentContext()
//        CGContextSetFillColorWithColor(ctx, bgColor?.CGColor ?? UIColor.whiteColor().colorWithAlphaComponent(0.3).CGColor)
//        CGContextBeginPath(ctx)
//        CGContextAddPath(ctx, Shapes.arrowToRightBGPath(bounds.size, arrowWidth: 20))
//        CGContextDrawPath(ctx, CGPathDrawingMode.Fill)
//    }
    
    func setOpen(_ open: Bool) {
        rightConstraint.constant = open ? 0 : 80
        UIView.animate(withDuration: 0.5, animations: {[weak self] in
            self?.layoutIfNeeded()
        }) 
    }
    
    func setTextColor(_ color: UIColor) {
        quantityLabel.textColor = color
    }
    
    // this is a hack to update the transform of the stash view together with the cart view because otherwise when we scale down the cart view, the stash view remains behind. TODO proper solution - we should put the cart and the stash view inside a new superview with controls this logic, such that we don't have to update them separately.
    func updateOpenStateForQuantities(_ cartQuantity: Float, stashQuantity: Float) {
        let expanded = cartQuantity > 0 || stashQuantity > 0
        setExpandedVertical(expanded, animated: true)
    }
    
    fileprivate func setExpandedVertical(_ expanded: Bool, animated: Bool) {
        if expanded != self.expanded {
            self.expanded = expanded
            
            if animated {
                heightConstraint.constant = expanded ? originalHeight : 0
                UIView.animate(withDuration: 0.3, animations: {[weak self] in
                    self?.superview?.layoutIfNeeded()
                }) 
            } else {
                heightConstraint.constant = expanded ? originalHeight : 0
                superview?.layoutIfNeeded()
            }
        }
    }
}
