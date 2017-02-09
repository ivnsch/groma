//
//  IngredientCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers


protocol IngredientCellDelegate: class {
    func onIncrementItemTap(_ cell: IngredientCell)
    func onDecrementItemTap(_ cell: IngredientCell)
    func onPanQuantityUpdate(_ cell: IngredientCell, newQuantity: Int)
}


class IngredientCell: UITableViewCell, SwipeToIncrementHelperDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    @IBOutlet weak var categoryColorView: UIView!
    
    var model: Ingredient? {
        didSet {
            guard let model = model else {QL3("Model is nil"); return}
            
            nameLabel.text = model.item.name
            
            shownQuantity = model.quantity
            
            categoryColorView.backgroundColor = model.item.category.color

            // height now calculated yet so we pass the position of border
            addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        }
    }
    
    weak var delegate: IngredientCellDelegate?
    
    var shownQuantity: Int = 0 {
        didSet {
//            let unitText = model.map{$0.product.unitText} ?? ""
//            quantityLabel.text = String("\(shownQuantity)\(unitText)")
            quantityLabel.text = String("\(shownQuantity)")
        }
    }
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: contentView)
        swipeToIncrementHelper?.delegate = self
        
        selectionStyle = .none
    }
    
    @IBAction func onIncrementTap(_ sender: UIButton) {
        delegate?.onIncrementItemTap(self)
    }
    
    @IBAction func onDecrementTap(_ sender: UIButton) {
        delegate?.onDecrementItemTap(self)
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
    
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Int {
        return shownQuantity
    }
    
    func onQuantityUpdated(_ quantity: Int) {
        shownQuantity = quantity
    }
    
    func onFinishSwipe() {
        delegate?.onPanQuantityUpdate(self, newQuantity: shownQuantity)
    }
}
