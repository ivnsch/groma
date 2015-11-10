//
//  InventorySharedUserCell.swift
//  shoppin
//
//  Created by ischuetz on 10/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventorySharedUserCell: UITableViewCell {
    
    @IBOutlet weak var emailLabel: UILabel!
    
    var sharedUser: SharedUser? {
        didSet {
            if let sharedUser = sharedUser {
                emailLabel.text = sharedUser.email
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
}
