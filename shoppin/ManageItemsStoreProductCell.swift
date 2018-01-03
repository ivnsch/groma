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

        // TODO needs probably a new view with refQuantity and refPrice - what we show in the price inputs popup in add/edit list item controller
        // and also probably needs unit and base quantity(ies)
//        storeNameLabel.text = storeProduct.store.isEmpty ? trans("manage_items_empty_store_name") : storeProduct.storeprice ?? 0
//        priceLabel.text = storeProduct.price.toLocalCurrencyString()

        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
