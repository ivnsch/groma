//
//  InventoryItemTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ProductWithQuantityTableViewCellDelegate {
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
    
    var model: ProductWithQuantity?
    
    var delegate: ProductWithQuantityTableViewCellDelegate?
    var row: Int?

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
