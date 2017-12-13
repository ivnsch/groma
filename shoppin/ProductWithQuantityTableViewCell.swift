//
//  InventoryItemTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol ProductWithQuantityTableViewCellDelegate: class {
    func onChangeQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float)
    func onQuantityInput(_ cell: ProductWithQuantityTableViewCell, quantity: Float)
    func onDeleteTap(_ cell: ProductWithQuantityTableViewCell)
}

class ProductWithQuantityTableViewCell: UITableViewCell, SwipeToIncrementHelperDelegate, SwipeToDeleteHelperDelegate, QuantityViewDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var quantityView: QuantityView!
    
    @IBOutlet weak var baseQuantityLabel: UILabel!
    @IBOutlet weak var deleteProgressContainer: UIView!
    @IBOutlet weak var deleteProgressViewWidth: NSLayoutConstraint!

    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!

    @IBOutlet weak var categoryColorView: UIView!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var myContentView: UIView!
    
    @IBOutlet weak var quantityViewTrailingConstraint: NSLayoutConstraint!

    fileprivate var swipeToDeleteHelper: SwipeToDeleteHelper?
    
    fileprivate var isAnimatingProgress: Bool = false
    fileprivate var animationCancelled: Bool = false

    var model: ProductWithQuantity2? {
        didSet {
            guard let model = model else {logger.w("Model is nil"); return}
            
            swipeToDeleteHelper?.setOpen(false, animated: false) // recycling
            
            nameLabel.text = NSLocalizedString(model.product.product.item.name, comment: "")
            
            centerVerticallyNameLabelConstraint.constant = model.product.product.brand.isEmpty ? 0 : 10
            brandLabel.text = model.product.product.brand
            
            baseQuantityLabel.text = model.product.baseText
                
            shownQuantity = model.quantity
            
            categoryColorView.backgroundColor = model.product.product.item.category.color
            
            cancelDeleteProgress() // some recycled cells were showing red bar on top
            
            // this was initially a local function but it seems we have to use a closure, see http://stackoverflow.com/a/26237753/930450
            // TODO change quantity / edit inventory items
            //        let incrementItem = {(quantity: Int) -> () in
            //            //let newQuantity = inventoryItem.quantity + quantity
            //            //if (newQuantity >= 0) {
            //                inventoryItem.quantityDelta += quantity
            //                self.inventoryItemsProvider.updateInventoryItem(inventoryItem)
            //                cell.quantityLabel.text = String(inventoryItem.quantity)
            //            //}
            //        }
            
            
            // height now calculated yet so we pass the position of border
            addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
            
            selectionStyle = UITableViewCellSelectionStyle.none
        }
    }
    var indexPath: IndexPath?
    
    weak var delegate: ProductWithQuantityTableViewCellDelegate?

    var shownQuantity: Float = 0 {
        didSet {
            if let _ = model?.product {
                quantityView.quantity = shownQuantity
//                quantityLabel.text = String("\(product.quantityWithMaybeUnitText(quantity: shownQuantity))") // TODO???????????? format?
            } else {
                logger.w("Warn? using quantity before model is set")
                //            let unitText = model.map{$0.product.unitText} ?? ""
//                quantityLabel.text = String("\(shownQuantity.quantityString)") // show something meaningful anyway. Maybe we can remove this.
                quantityView.quantity = shownQuantity
            }
            
//            if shownQuantity == 0 && oldValue != 0 {
//                UIView.animate(withDuration: Theme.defaultAnimDuration) {[weak self] in
//                    self?.contentView.backgroundColor = Theme.lightPink
//                }
//            } else {
//                contentView.backgroundColor = UIColor.white
//            }
        }
    }
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        swipeToDeleteHelper = SwipeToDeleteHelper(parentView: self, button: myContentView, leftLayoutConstraint: leftLayoutConstraint, rightLayoutConstraint: rightLayoutConstraint, cancelTouches: false)
        swipeToDeleteHelper?.delegate = self
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: contentView)
        swipeToIncrementHelper?.delegate = self
        
        selectionStyle = .none

        setMode(.readonly, animated: false) // default
        quantityView.delegate = self

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPress)
    }

    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began: setMode(quantityView.mode == .edit ? .readonly : .edit, animated: true)
        default: break
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        func animate(_ alpha: CGFloat) {
            UIView.animate(withDuration: 0.2, animations: {[weak self] in
                self?.categoryColorView.alpha = alpha
            }) 
        }

        if editing {
            animate(0)
        } else {
            animate(1)
        }
    }
    
    func startDeleteProgress(_ onComplete: @escaping VoidFunction) {
        deleteProgressViewWidth.constant = deleteProgressContainer.frame.width
        isAnimatingProgress = true
        animationCancelled = false
        
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {[weak self] in
            self?.contentView.layoutIfNeeded()
        }, completion: {[weak self] finished in
            self?.isAnimatingProgress = false
            
            if !(self?.animationCancelled ?? false) {
                onComplete()
            }
        })
    }

    
    func cancelDeleteProgress() {
        deleteProgressViewWidth.constant = 0
        
        if isAnimatingProgress { // make sure to cancel only the progress animation

            animationCancelled = true // with removeAllAnimations completion is still called, so we use a flag
            
            CATransaction.begin()
            layer.removeAllAnimations()
            CATransaction.commit()
        }
    }
    
    func setMode(_ mode: QuantityViewMode, animated: Bool) {
        isEditing = mode == .edit
        quantityViewTrailingConstraint.constant = mode == .edit ? DimensionsManager.leftRightPaddingConstraint :
            DimensionsManager.leftRightPaddingConstraint
        quantityView.setMode(mode, animated: animated)
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return shownQuantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        guard let model = model else {logger.e("Illegal state: No model"); return}
        
        let delta = shownQuantity - model.quantity
        
        shownQuantity = quantity
        quantityView.showDelta(delta)
    }
    
    func onFinishSwipe() {
        guard let model = model else {logger.e("Illegal state: No model"); return}

        let delta = shownQuantity - model.quantity
        delegate?.onChangeQuantity(self, delta: delta)
    }
    
    var swipeToIncrementEnabled: Bool {
        let isSwipeToDeleteOpen = swipeToDeleteHelper?.isOpen ?? false
        return !isSwipeToDeleteOpen && isEditing
    }
    
    // MARK: -
    
    @IBAction func onDeleteTap() {
//        delegate?.onDeleteTap(self)
    }
    
    // MARK: - SwipeToDeleteHelperDelegate
    
    func onOpen(_ open: Bool) {
        if open {
            delegate?.onDeleteTap(self)
        }
    }
    
    var isSwipeToDeleteEnabled: Bool {
        return shownQuantity == 0
    }
    
    // MARK: - QuantityViewDelegate
    
    func onRequestUpdateQuantity(_ delta: Float) {
        shownQuantity = shownQuantity + delta // increment in advance // TODO!!!!!!!!!!!!!!!! test if this always works as intented
        delegate?.onChangeQuantity(self, delta: delta)
    }
    
    func onQuantityInput(_ quantity: Float) {
        delegate?.onQuantityInput(self, quantity: quantity)
    }
}
