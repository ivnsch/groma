//
//  PricesView.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

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
    
    fileprivate(set) var totalPrice: Float?
    fileprivate(set) var donePrice: Float?
    
    var originalHeight: CGFloat = 0
    fileprivate var originalPriceFont: UIFont!
    fileprivate var originalCartImgLeftConstraint: CGFloat = 0
    
    let minimizedHeight: CGFloat = 20
    
    fileprivate let arrowWidth: CGFloat = 20
    fileprivate let openWidth: CGFloat = -60 // width constant while showing stash view behind
    
    fileprivate(set) var open: Bool = false // when stash view behind is visible
    fileprivate var expanded: Bool = true // if vertically minimized or expanded (expanded is normal size)

    var allowOpen: Bool = false {
        didSet {
            cellUncoverer?.allowOpen = allowOpen
        }
    }
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    fileprivate var cellUncoverer: CellUncoverer?

    fileprivate var cartQuantity: Int = 0 {
        didSet {
            if let cartQuantityLabel = quantityLabel {
                if cartQuantity == 1 {
                    cartQuantityLabel.text = trans("list_items_items_in_cart_singular", "\(cartQuantity)")
                } else {
                    cartQuantityLabel.text = trans("list_items_items_in_cart_plural", "\(cartQuantity)")
                }
                
            } else {
                QL3("Setting cart quantity but label is not initialised yet")
            }
        }
    }

    var quantities: (cart: Int, stash: Int) = (0, 0) {
        didSet {
            if let _ = quantityLabel {
                cartQuantity = quantities.cart
                stashQuantity = quantities.stash

                checkExpandedVertical()
                updateQuantityCenterConstraint()
                
            } else {
                QL3("Setting quantities but labels not initialised yet")
            }
        }
    }
    
    fileprivate var stashQuantity: Int = 0 {
        didSet {
            if let stashQuantityLabel = stashQuantityLabel {
                stashQuantityLabel.text = trans("list_items_items_in_backstore", "\(stashQuantity)")
                stashQuantityLabel.isHidden = stashQuantity == 0
            } else {
                QL3("Setting stash quantity but label is not initialised yet")
            }
        }
    }
    
    fileprivate func updateQuantityCenterConstraint() {
        quantityCenterConstraint.constant = stashQuantity == 0 ? 0 : -10
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        backgroundColor = UIColor.clearColor() // we add the background with layer (because of triangle shape)
        originalHeight = DimensionsManager.listItemsPricesViewHeight
        originalPriceFont = totalPriceLabel.font
        originalCartImgLeftConstraint = cartImgLeftConstraint.constant

        setExpandedVerticalSimple(false, animated: false)
        
        clipsToBounds = true
        
        cellUncoverer = CellUncoverer(parentView: self, button: button, leftLayoutConstraint: leftLayoutConstraint)
        cellUncoverer?.delegate = self
    }
    
    // MARK: - CellUncovererDelegate
    
    func onOpen(_ open: Bool) {
        self.open = open
    }

    // MARK -
    
    func setOpen(_ open: Bool, animated: Bool = true) {
        self.open = open
        cellUncoverer?.setOpen(open, animated: animated)
    }
      
    func setTotalPrice(_ price: Float, animated: Bool) {
        self.totalPrice = price
        updateTotalPriceLabel(animated)
    }
    
    fileprivate func updateTotalPriceLabel(_ animated: Bool) {
        if let totalPrice = totalPrice {
            let text = donePrice == 0 ? totalPrice.toLocalCurrencyString() : "/ \(totalPrice.toLocalCurrencyString())"
            updatePriceLabel(text, label: totalPriceLabel, animated: animated)
        }
    }
    
    func setDonePrice(_ price: Float, animated: Bool) {
        self.donePrice = price
        let text = price.toLocalCurrencyString()
        updatePriceLabel(text, label: donePriceLabel, animated: animated)
        updateTotalPriceLabel(false) // depending if done price is 0 (empty - not visible) or not, total label gets a leading "/", so we have to refresh it
    }
    
    fileprivate func updatePriceLabel(_ text: String, label: UILabel, animated: Bool) {
        if text != label.text {
            label.text = text
            
            if animated {
                UIView.animate(withDuration: 0.15, animations: {
                    label.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    label.font = Fonts.largeBold
                }, completion: {finished in
                    UIView.animate(withDuration: 0.15, animations: {
                        label.transform = CGAffineTransform.identity
                        label.font = Fonts.regularLight
                        }, completion: {finished in
                    }) 
                }) 
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
    func setExpandedHorizontal(_ expanded: Bool) {
        open = !expanded
//        widthConstraint.constant = widthConstant
//        UIView.animateWithDuration(0.5) {[weak self] in
//            self?.layoutIfNeeded()
//        }
    }
    
    fileprivate var widthConstant: CGFloat {
        return open ? openWidth : 0
    }

    
    fileprivate func checkExpandedVertical() {
        let expanded = cartQuantity > 0 || stashQuantity > 0
        setExpandedVerticalSimple(expanded, animated: true)
    }
    
    fileprivate func setExpandedVerticalSimple(_ expanded: Bool, animated: Bool) {
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
    
    // TODO this is from old UI, remove
    func setExpandedVertical(_ expanded: Bool) {
        if expanded != self.expanded {
            self.expanded = expanded
            
            if let superview = superview {
                heightConstraint.constant = expanded ? originalHeight : minimizedHeight
                cartImgLeftConstraint.constant = expanded ? originalCartImgLeftConstraint : -38 // -38: -(img width + img left constraint)
                widthConstraint.constant = expanded ? widthConstant : superview.frame.width + arrowWidth
                UIView.animate(withDuration: 0.3, animations: {[weak self] in
                    self?.layoutIfNeeded()
                    self?.cartImg.alpha = expanded ? 1 : 0
                    let scale: CGFloat = expanded ? 1.3 : 0.7
                    self?.totalPriceLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
                    self?.donePriceLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
                    }, completion: {[weak self] finished in
                        if let weakSelf = self {
                            let font = expanded ? weakSelf.originalPriceFont : Fonts.verySmallLight
                            weakSelf.totalPriceLabel.font = font
                            weakSelf.donePriceLabel.font = font
                            self?.totalPriceLabel.transform = CGAffineTransform.identity
                            self?.donePriceLabel.transform = CGAffineTransform.identity
                            weakSelf.layoutIfNeeded()
                        }
                    })
            } else {
                print("Warn: PricesView.setExpandedVertical: no superview")
            }
        }
    }
}
