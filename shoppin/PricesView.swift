//
//  PricesView.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class PricesView: UIView, UIGestureRecognizerDelegate {

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

    @IBOutlet weak var button: UIButton!
    
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
    
    var panRecognizer: UIPanGestureRecognizer!
    var panStartPoint: CGPoint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    var startingLeftLayoutConstraint: CGFloat!
    var allowOpen: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgroundColor = UIColor.clearColor() // we add the background with layer (because of triangle shape)
//        originalHeight = heightConstraint.constant
        heightConstraint.constant = DimensionsManager.listItemsPricesViewHeight
        originalPriceFont = totalPriceLabel.font
        originalCartImgLeftConstraint = cartImgLeftConstraint.constant
        
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "onPanCell:")
        panRecognizer.delegate = self
        self.button.addGestureRecognizer(panRecognizer)
        self.panRecognizer = panRecognizer
    }
    
    
    func onPanCell(recognizer:UIPanGestureRecognizer) {
    
        guard allowOpen else {return}
        
        let stashViewWidth: CGFloat = 60
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .Began:
            self.panStartPoint = recognizer.translationInView(self.button)
            self.startingLeftLayoutConstraint = self.leftLayoutConstraint.constant
            
        case .Changed:
            if movingHorizontally {
                let currentPoint = recognizer.translationInView(self)
                let deltaX = abs(currentPoint.x - self.panStartPoint.x)
                let panningLeft = currentPoint.x < self.panStartPoint.x
                
                if panningLeft {
                    if deltaX < stashViewWidth {
                        leftLayoutConstraint.constant = startingLeftLayoutConstraint - deltaX
                    } else {
                        
                        leftLayoutConstraint.constant = startingLeftLayoutConstraint - ((stashViewWidth + (deltaX - stashViewWidth) / 2))
                    }
                } else {
                    leftLayoutConstraint.constant = min(0, startingLeftLayoutConstraint + deltaX)
                }
            }
            
        case .Ended:
            if movingHorizontally {
                if abs(leftLayoutConstraint.constant) < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if abs(leftLayoutConstraint.constant) >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    open = true
                }
                UIView.animateWithDuration(0.3) {[weak self] in
                    self?.layoutIfNeeded()
                }
            }
            
        case .Cancelled:
            if movingHorizontally {
                if leftLayoutConstraint.constant < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if leftLayoutConstraint.constant >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    open = true
                }
                UIView.animateWithDuration(0.3) {[weak self] in
                    self?.layoutIfNeeded()
                }
            }
            
        default:
            "Not handled"
        }
    }

    // TODO generic open/close
    func close() {
        open = false
        leftLayoutConstraint.constant = 0
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.layoutIfNeeded()
        }
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