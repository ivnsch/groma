//
//  EmptyViewCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 28/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class EmptyViewCell: UITableViewCell {

    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
