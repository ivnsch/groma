//
//  ListSharedUserCell.swift
//  
//
//  Created by ischuetz on 09/11/15.
//
//

import UIKit

class ListSharedUserCell: UITableViewCell {

    @IBOutlet weak var qemailLabel: UILabel!
    
    var sharedUser: SharedUser? {
        didSet {
            if let sharedUser = sharedUser {
                qemailLabel.text = sharedUser.email
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
}
