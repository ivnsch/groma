//
//  ReorderSectionCell.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ReorderSectionCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    var section: Section? {
        didSet {
            if let section = section {
                nameLabel.text = section.name
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
