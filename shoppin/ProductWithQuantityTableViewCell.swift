//
//  InventoryItemTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ProductWithQuantityTableViewCellDelegate: class {
    func onIncrementItemTap(cell: ProductWithQuantityTableViewCell)
    func onDecrementItemTap(cell: ProductWithQuantityTableViewCell)
    func onPanQuantityUpdate(cell: ProductWithQuantityTableViewCell, newQuantity: Int)
}

class ProductWithQuantityTableViewCell: UITableViewCell, SwipeToIncrementHelperDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var deleteProgressContainer: UIView!
    @IBOutlet weak var deleteProgressViewWidth: NSLayoutConstraint!

    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!

    @IBOutlet weak var categoryColorView: UIView!
    
    private var isAnimatingProgress: Bool = false
    private var animationCancelled: Bool = false
    
    var model: ProductWithQuantity? {
        didSet {
            guard let model = model else {QL3("Model is nil"); return}
            
            nameLabel.text = NSLocalizedString(model.product.name, comment: "")
            
            centerVerticallyNameLabelConstraint.constant = model.product.brand.isEmpty ? 0 : 10
            brandLabel.text = model.product.brand
            
            quantityLabel.text = String(model.quantity)
            shownQuantity = model.quantity
            
            categoryColorView.backgroundColor = model.product.category.color
            
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
            
            selectionStyle = UITableViewCellSelectionStyle.None
        }
    }
    
    weak var delegate: ProductWithQuantityTableViewCellDelegate?

    var shownQuantity: Int = 0 {
        didSet {
            quantityLabel.text = String("\(shownQuantity)")
        }
    }
    
    private var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: contentView)
        swipeToIncrementHelper?.delegate = self
    }
    
    @IBAction func onIncrementTap(sender: UIButton) {
        delegate?.onIncrementItemTap(self)
    }
    
    @IBAction func onDecrementTap(sender: UIButton) {
        delegate?.onDecrementItemTap(self)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        func animate(alpha: CGFloat) {
            UIView.animateWithDuration(0.2) {[weak self] in
                self?.categoryColorView.alpha = alpha
            }
        }

        if editing {
            animate(0)
        } else {
            animate(1)
        }
    }
    
    func startDeleteProgress(onComplete: VoidFunction) {
        deleteProgressViewWidth.constant = deleteProgressContainer.frame.width
        isAnimatingProgress = true
        animationCancelled = false
        
        UIView.animateWithDuration(1, delay: 0, options: .CurveLinear, animations: {[weak self] in
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
    
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Int {
        return shownQuantity
    }
    
    func onQuantityUpdated(quantity: Int) {
        shownQuantity = quantity
    }
    
    func onFinishSwipe() {
        delegate?.onPanQuantityUpdate(self, newQuantity: shownQuantity)
    }
}
