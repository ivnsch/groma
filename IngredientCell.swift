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
}


class IngredientCell: UITableViewCell {
    
    @IBOutlet weak var categoryColorView: UIView!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var fractionView: FractionView!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var unitLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLeadingConstraint: NSLayoutConstraint!
    
    var ingredient: Ingredient? {
        didSet {
            guard let ingredient = ingredient else {QL3("Model is nil"); return}
            
            nameLabel.text = ingredient.item.name
            
            quantityLabel.text = ingredient.quantity.quantityStringHideZero
            
            unitLabel.text = ingredient.unit.name
            if ingredient.unit.name.isEmpty {
                unitLeadingConstraint.constant = 0
            } else {
                unitLeadingConstraint.constant = 8
            }
            
            fractionView.fraction = DBFraction(numerator: ingredient.fraction.numerator, denominator: ingredient.fraction.denominator)
            
            categoryColorView.backgroundColor = ingredient.item.category.color

            // height now calculated yet so we pass the position of border
            addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
        }
    }
    
    weak var delegate: IngredientCellDelegate?

    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    func setRightSideOffset(offset: CGFloat, animated: Bool) {
     
        func f() {
            nameLeadingConstraint.constant = offset
        }
        
        if animated {
            UIView.animate(withDuration: Theme.defaultAnimDuration) {
                f()
            }
            
            
        } else {
            f()
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
}
