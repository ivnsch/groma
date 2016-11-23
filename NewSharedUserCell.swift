//
//  NewSharedUserCell.swift
//  shoppin
//
//  Created by ischuetz on 24/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol NewSharedUserCellDelegate: class {
    func onAddSharedUser(_ sharedUser: SharedUser, cell: NewSharedUserCell)
}

class NewSharedUserCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!

    weak var delegate: NewSharedUserCellDelegate?
    
    var sharedUser: SharedUser? {
        didSet {
            emailLabel.text = sharedUser?.email
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    @IBAction func onAddTap(_ sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onAddSharedUser(sharedUser, cell: self)
        } else {
            QL4("Shared user is not set")
        }
    }
}
