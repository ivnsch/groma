//
//  ExistingSharedUserCell.swift
//  shoppin
//
//  Created by ischuetz on 24/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ExistingSharedUserCellDelegate {
    func onDeleteSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell)
    func onPullSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell)
}

class ExistingSharedUserCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    
    var delegate: ExistingSharedUserCellDelegate?
    
    var sharedUser: SharedUser? {
        didSet {
            emailLabel.text = sharedUser?.email
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }

    @IBAction func onDeleteTap(sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onDeleteSharedUser(sharedUser, cell: self)
        } else {
            QL4("Shared user is not set")
        }
    }
    
    @IBAction func onPullTap(sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onPullSharedUser(sharedUser, cell: self)
        } else {
            QL4("Shared user is not set")
        }
    }
}
