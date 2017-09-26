//
//  MoreCell.swift
//  shoppin
//
//  Created by ischuetz on 08/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class MoreCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    var moreItem: MoreItem? {
        didSet {
            if let label = label {
                label.text = moreItem?.text
            } else {
                logger.w("Outlets not set")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // When returning cell height programatically, here it's still the height from the storyboard so we have to pass the offset for the line to eb draw at the bottom.
        contentView.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
    }
}
