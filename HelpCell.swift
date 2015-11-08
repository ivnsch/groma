//
//  HelpCell.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class HelpCell: UITableViewCell {

    @IBOutlet weak var helpLabel: UILabel!
    
    var sectionModel: HelpItemSectionModel? {
        didSet {
            if let sectionModel = sectionModel {
                helpLabel.text = sectionModel.obj.text
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
}