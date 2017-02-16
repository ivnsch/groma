//
//  ManageItemsBaseQuantityCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class ManageItemsBaseQuantityCell: UITableViewCell {
    
    @IBOutlet weak var baseLabel: UILabel!
    
    func config(base: String) {
        
        baseLabel.text = base
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
