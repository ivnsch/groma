//
//  PricesView.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PricesView: UIView {

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    private(set) var totalPrice: Float?
    private(set) var donePrice: Float?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clearColor() // we add the background with layer (because of triangle shape)
    }
    
    func setTotalPrice(price: Float, animated: Bool) {
        self.totalPrice = price
        updateTotalPriceLabel(animated)
    }
    
    private func updateTotalPriceLabel(animated: Bool) {
        if let totalPrice = totalPrice {
            let text = donePrice == 0 ? totalPrice.toLocalCurrencyString() : "/ \(totalPrice.toLocalCurrencyString())"
            updatePriceLabel(text, label: totalPriceLabel, animated: animated)
        }
    }
    
    func setDonePrice(price: Float, animated: Bool) {
        self.donePrice = price
        if price == 0 { // done price 0 should be invisible
            donePriceLabel.text = ""
        } else {
            let text = price.toLocalCurrencyString()
            updatePriceLabel(text, label: donePriceLabel, animated: animated)
        }
        updateTotalPriceLabel(false) // depending if done price is 0 (empty - not visible) or not, total label gets a leading "/", so we have to refresh it
    }
    
    private func updatePriceLabel(text: String, label: UILabel, animated: Bool) {
        if text != label.text {
            label.text = text
            
            if animated {
                UIView.animateWithDuration(0.15, animations: {
                    label.transform = CGAffineTransformMakeScale(1.05, 1.05)
                    label.font = Fonts.largeBold
                }) {finished in
                    UIView.animateWithDuration(0.15, animations: {
                        label.transform = CGAffineTransformIdentity
                        label.font = Fonts.regularLight
                        }) {finished in
                    }
                }
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextBeginPath(ctx)
        CGContextAddPath(ctx, Shapes.arrowToRightBGPath(bounds.size, arrowWidth: 20))
        CGContextDrawPath(ctx, CGPathDrawingMode.Fill)
    }
    
    // expanded: covers all width, contracted: space to see stash view
    func setExpanded(expanded: Bool) {
        widthConstraint.constant = expanded ? 0 : -80
        UIView.animateWithDuration(0.5) {[weak self] in
            self?.layoutIfNeeded()
        }
    }
}