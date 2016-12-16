//
//  MyAutocompleteCell.swift
//  shoppin
//
//  Created by ischuetz on 25/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class MyAutocompleteCell: UITableViewCell {
    
    var deleteTapHandler: VoidFunction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @IBAction func onDeleteTap(_ sender: UIButton) {
        deleteTapHandler?()
    }
}
