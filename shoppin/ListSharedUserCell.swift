//
//  ListSharedUserCell.swift
//  
//
//  Created by ischuetz on 09/11/15.
//
//

import UIKit
import QorumLogs
import Providers

protocol SharedUserCellDelegate: class {
    func onPullProductsTap(_ user: DBSharedUser, cell: ListSharedUserCell)
}

class SharedUserCellModel {
    let user: DBSharedUser
    var acceptedInvitation: Bool // for now we assume that users passed in edit mode have accepted the invitation.
    init(user: DBSharedUser, acceptedInvitation: Bool = false) {
        self.user = user
        self.acceptedInvitation = acceptedInvitation
    }
}

class ListSharedUserCell: UITableViewCell {

    @IBOutlet weak var qemailLabel: UILabel!
    
    @IBOutlet weak var pullProductsButton: UIButton!
    
    weak var delegate: SharedUserCellDelegate?
    
    var cellModel: SharedUserCellModel? {
        didSet {
            if let cellModel = cellModel {
                qemailLabel.text = cellModel.user.email
                pullProductsButton.isHidden = !cellModel.acceptedInvitation
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
//        contentView.backgroundColor = UICOlor
    }
    
    @IBAction func onPullProductsTap(_ sender: UIBarButtonItem) {
        if let sharedUser = cellModel?.user {
            delegate?.onPullProductsTap(sharedUser, cell: self)
        } else {
            QL4("Illegal state: cell has no shared user")
        }
    }
}
