//
//  PricesView.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class PricesView: UIView, UIGestureRecognizerDelegate, CellUncovererDelegate {

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cartImgLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var cartImg: UIImageView!

    @IBOutlet weak var quantityCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stashQuantityLabel: UILabel!
    
    private(set) var totalPrice: Float?
    private(set) var donePrice: Float?
    
    var originalHeight: CGFloat = 0
    private var originalPriceFont: UIFont!
    private var originalCartImgLeftConstraint: CGFloat = 0
    
    let minimizedHeight: CGFloat = 20
    
    private let arrowWidth: CGFloat = 20
    private let openWidth: CGFloat = -60 // width constant while showing stash view behind
    
    private(set) var open: Bool = false // when stash view behind is visible
    private var expanded: Bool = true // if vertically minimized or expanded (expanded is normal size)

    var allowOpen: Bool = false {
        didSet {
            cellUncoverer?.allowOpen = allowOpen
        }
    }
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    private var cellUncoverer: CellUncoverer?

    var cartQuantity: Int = 0 {
        didSet {
            if let cartQuantityLabel = quantityLabel {
                cartQuantityLabel.text = "\(cartQuantity) items in your cart"
                updateQuantityCenterConstraint()
            } else {
                QL3("Setting cart quantity but label is not initialised yet")
            }
        }
    }

    var stashQuantity: Int = 0 {
        didSet {
            if let stashQuantityLabel = stashQuantityLabel {
                stashQuantityLabel.text = "\(stashQuantity) in the backstore"
                updateQuantityCenterConstraint()
                stashQuantityLabel.hidden = stashQuantity == 0
            } else {
                QL3("Setting stash quantity but label is not initialised yet")
            }
        }
    }
    
    private func updateQuantityCenterConstraint() {
        quantityCenterConstraint.constant = stashQuantity == 0 ? 0 : -10
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgroundColor = UIColor.clearColor() // we add the background with layer (because of triangle shape)
//        originalHeight = heightConstraint.constant
        heightConstraint.constant = DimensionsManager.listItemsPricesViewHeight
        originalPriceFont = totalPriceLabel.font
        originalCartImgLeftConstraint = cartImgLeftConstraint.constant
        
        cellUncoverer = CellUncoverer(parentView: self, button: button, leftLayoutConstraint: leftLayoutConstraint)
        cellUncoverer?.delegate = self
    }
    
    // MARK: - CellUncovererDelegate
    
    func onOpen(open: Bool) {
        self.open = open
    }

    // TODO generic open/close
    func close() {
        open = false
        cellUncoverer?.close()
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
        let text = price.toLocalCurrencyString()
        updatePriceLabel(text, label: donePriceLabel, animated: animated)
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
//
    // this is to draw arrow shape on the right side - for now disabled
//    override func drawRect(rect: CGRect) {
//        let ctx = UIGraphicsGetCurrentContext()
//        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
//        CGContextBeginPath(ctx)
//        CGContextAddPath(ctx, Shapes.arrowToRightBGPath(bounds.size, arrowWidth: arrowWidth))
//        CGContextDrawPath(ctx, CGPathDrawingMode.Fill)
//    }
    
    // expanded: covers all width, contracted: space to see stash view
    func setExpandedHorizontal(expanded: Bool) {
        open = !expanded
//        widthConstraint.constant = widthConstant
//        UIView.animateWithDuration(0.5) {[weak self] in
//            self?.layoutIfNeeded()
//        }
    }
    
    private var widthConstant: CGFloat {
        return open ? openWidth : 0
    }
    
    func setExpandedVertical(expanded: Bool) {
        if expanded != self.expanded {
            self.expanded = expanded
            
            if let superview = superview {
                heightConstraint.constant = expanded ? originalHeight : minimizedHeight
                cartImgLeftConstraint.constant = expanded ? originalCartImgLeftConstraint : -38 // -38: -(img width + img left constraint)
                widthConstraint.constant = expanded ? widthConstant : superview.frame.width + arrowWidth
                UIView.animateWithDuration(0.3, animations: {[weak self] in
                    self?.layoutIfNeeded()
                    self?.cartImg.alpha = expanded ? 1 : 0
                    let scale: CGFloat = expanded ? 1.3 : 0.7
                    self?.totalPriceLabel.transform = CGAffineTransformMakeScale(scale, scale)
                    self?.donePriceLabel.transform = CGAffineTransformMakeScale(scale, scale)
                    }, completion: {[weak self] finished in
                        if let weakSelf = self {
                            let font = expanded ? weakSelf.originalPriceFont : Fonts.verySmallLight
                            weakSelf.totalPriceLabel.font = font
                            weakSelf.donePriceLabel.font = font
                            self?.totalPriceLabel.transform = CGAffineTransformIdentity
                            self?.donePriceLabel.transform = CGAffineTransformIdentity
                            weakSelf.layoutIfNeeded()
                        }
                    })
            } else {
                print("Warn: PricesView.setExpandedVertical: no superview")
            }
        }
    }
}