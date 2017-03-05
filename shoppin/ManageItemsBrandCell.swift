//
//  ManageItemsBrandCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class ManageItemsBrandCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    func config(brand: String, filter: String?) {
        
        if let boldRange = filter.flatMap({brand.range($0, caseInsensitive: true)}) {
            nameLabel.attributedText = brand.makeAttributedBoldRegular(boldRange)
        } else {
            nameLabel.text = brand
        }
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
