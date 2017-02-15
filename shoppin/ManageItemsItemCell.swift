//
//  ManageItemsItemCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

class ManageItemsItemCell: UITableViewCell {

    @IBOutlet weak var categoryColorView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    @IBOutlet weak var nameLeadingConstraint: NSLayoutConstraint!

    fileprivate var categoryColor: UIColor?
    
    func config(item: Item) {
        
        nameLabel.text = item.name
        categoryNameLabel.text = item.category.name
        
        updateCategoryColorVisibility(animated: false)
        
        categoryColor = item.category.color
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        updateCategoryColorVisibility(animated: animated)
    }
    
    fileprivate func updateCategoryColorVisibility(animated: Bool) {
        guard let categoryColor = categoryColor else {return}
        
        animIf(animated) {[weak self] in guard let weakSelf = self else {return}
            weakSelf.categoryColorView.backgroundColor = weakSelf.isEditing ? UIColor.clear : categoryColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
