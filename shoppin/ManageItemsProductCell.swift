//
//  ManageItemsProductCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 15/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageItemsProductCell: UITableViewCell {

    @IBOutlet weak var brandLabel: UILabel!

    func config(product: Product) {
        
        brandLabel.text = product.brand.isEmpty ? trans("product_empty_brand_name") : product.brand
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
