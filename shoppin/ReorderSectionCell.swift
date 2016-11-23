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
                contentView.backgroundColor = section.color
                backgroundColor = section.color
                nameLabel.textColor = UIColor.white
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
    }
}
