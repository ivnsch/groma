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
    
    func config(base: Float, filter: String?) {
        
        let baseText = base.quantityString
        
        if let boldRange = filter.flatMap({baseText.range($0, caseInsensitive: true)}) {
            baseLabel.attributedText = baseText.makeAttributedBoldRegular(boldRange)
        } else {
            baseLabel.text = baseText
        }
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
