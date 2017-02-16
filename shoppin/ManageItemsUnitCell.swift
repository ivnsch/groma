//
//  ManageItemsUnitCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageItemsUnitCell: UITableViewCell {
    
    @IBOutlet weak var unitLabel: UILabel!
    
    func config(unit: Providers.Unit) {
        
        unitLabel.text = unit.name.isEmpty ? "unit_none_name" : unit.name
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
