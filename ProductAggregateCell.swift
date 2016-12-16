//
//  ProductAggregateCell.swift
//  shoppin
//
//  Created by ischuetz on 31/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ProductAggregateCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    
    var productAggregate: ProductAggregate? {
        didSet {
            if let productAggregate = productAggregate {
                nameLabel.text = productAggregate.product.name
                priceLabel.text = productAggregate.totalPrice.toLocalCurrencyString()
                percentLabel.text = "\(productAggregate.percentage.toString(1)) %"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
}
