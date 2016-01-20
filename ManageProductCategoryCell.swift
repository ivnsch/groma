//
//  ManageProductCategoryCell.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class ManageProductCategoryCell: UITableViewCell {
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    var category: ProductCategory? {
        didSet {
            if let category = category {
                categoryNameLabel.text = category.name
                contentView.backgroundColor = category.color.colorWithAlphaComponent(0.5)
            }
        }
    }
}