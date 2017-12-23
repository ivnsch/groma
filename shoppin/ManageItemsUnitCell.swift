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
    @IBOutlet weak var buyableLabel: UILabel!
    
    func config(unit: Providers.Unit, filter: String?) {
        
        let unitNameText = unit.name.isEmpty ? trans("unit_unit") : unit.name
        
        if let boldRange = filter.flatMap({unitNameText.range($0, caseInsensitive: true)}) {
            unitLabel.attributedText = unitNameText.makeAttributedBoldRegular(boldRange)
        } else {
            unitLabel.text = unitNameText
        }
        
        if unit.buyable {
            buyableLabel.text = trans("button_title_buyable")
        } else {
            buyableLabel.text = ""
        }
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
