//
//  ExistingSharedUserCell.swift
//  shoppin
//
//  Created by ischuetz on 24/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol ExistingSharedUserCellDelegate: class {
    func onDeleteSharedUser(_ sharedUser: DBSharedUser, cell: ExistingSharedUserCell)
    func onPullSharedUser(_ sharedUser: DBSharedUser, cell: ExistingSharedUserCell)
}

class ExistingSharedUserCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    
    weak var delegate: ExistingSharedUserCellDelegate?
    
    var sharedUser: DBSharedUser? {
        didSet {
            emailLabel.text = sharedUser?.email
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    @IBAction func onDeleteTap(_ sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onDeleteSharedUser(sharedUser, cell: self)
        } else {
            logger.e("Shared user is not set")
        }
    }
    
    @IBAction func onPullTap(_ sender: UIButton) {
        if let sharedUser = sharedUser {
            delegate?.onPullSharedUser(sharedUser, cell: self)
        } else {
            logger.e("Shared user is not set")
        }
    }
}
