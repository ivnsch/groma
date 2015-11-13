//
//  QuickAddGroupCell.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddGroupCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var item: QuickAddGroup? {
        didSet {
            if let item = item {
                nameLabel.text = item.labelText
            }
        }
    }
}