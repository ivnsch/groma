//
//  ManageBrandsCell.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class ManageBrandsCell: UITableViewCell {
    
    @IBOutlet weak var brandNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    var brand: String? {
        didSet {
            brandNameLabel.text = brand
        }
    }
}