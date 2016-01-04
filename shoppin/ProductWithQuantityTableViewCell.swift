//
//  InventoryItemTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ProductWithQuantityTableViewCellDelegate {
    func onIncrementItemTap(cell: ProductWithQuantityTableViewCell)
    func onDecrementItemTap(cell: ProductWithQuantityTableViewCell)
}

class ProductWithQuantityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var deleteProgressContainer: UIView!
    @IBOutlet weak var deleteProgressViewWidth: NSLayoutConstraint!

    private var isAnimatingProgress: Bool = false
    private var animationCancelled: Bool = false
    
    var model: ProductWithQuantity?
    
    var delegate: ProductWithQuantityTableViewCellDelegate?
    var row: Int?
    
    @IBAction func onIncrementTap(sender: UIButton) {
        delegate?.onIncrementItemTap(self)
    }
    
    @IBAction func onDecrementTap(sender: UIButton) {
        delegate?.onDecrementItemTap(self)
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
}
