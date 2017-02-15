//
//  ManageItemsStoreProductCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 15/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageItemsStoreProductCell: UITableViewCell {
    
    @IBOutlet weak var storeNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    func config(storeProduct: StoreProduct) {
        
        storeNameLabel.text = storeProduct.store.isEmpty ? trans("manage_items_empty_store_name") : storeProduct.store
        priceLabel.text = storeProduct.price.toLocalCurrencyString()
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
