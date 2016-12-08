//
//  InvitedUserCell.swift
//  shoppin
//
//  Created by ischuetz on 25/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol InvitedSharedUserCellDelegate: class {
    func onInviteInfoSharedUser(_ sharedUser: DBSharedUser, cell: InvitedUserCell)
}

class InvitedUserCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    
    weak var delegate: InvitedSharedUserCellDelegate?
    
    var sharedUser: DBSharedUser? {
        didSet {
            emailLabel.text = sharedUser?.email
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    @IBAction func onInfoTap(_ sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onInviteInfoSharedUser(sharedUser, cell: self)
        } else {
            QL4("Shared user is not set")
        }
    }
}
