//
//  ManageItemsQuantifiableProductCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 15/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageItemsQuantifiableProductCell: UITableViewCell {

    @IBOutlet weak var baseQuantityLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var unitLeadingConstraint: NSLayoutConstraint!

    func config(quantifiableProduct: QuantifiableProduct) {
        
        baseQuantityLabel.text = quantifiableProduct.baseQuantity
        unitLabel.text = quantifiableProduct.unit.name
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
