//
//  ExpandableItemsTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

class ExpandableItemsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var listName: UILabel!
    @IBOutlet weak var userCountLabel: UILabel!
    @IBOutlet weak var usersIcon: UIImageView!

    var model: ExpandableTableViewModel? {
        didSet {
            if let model = model {
                listName.text = model.name
                
                let c = model.bgColor
                contentView.backgroundColor = c
                backgroundColor = c
                let v = UIView()
                v.backgroundColor = c
                selectedBackgroundView = v
                
                let contrastingTextColor = UIColor(contrastingBlackOrWhiteColorOn: model.bgColor, isFlat: true)
                listName.textColor = contrastingTextColor
                
                let showUserInfo = model.users.count > 0
                
                usersIcon.hidden = !showUserInfo
                userCountLabel.hidden = !showUserInfo
                
                if showUserInfo {
                    userCountLabel.text = "\(model.users.count)"
                    usersIcon.tintColor = contrastingTextColor
                    userCountLabel.textColor = contrastingTextColor
                } else {
                    userCountLabel.text = ""
                }
                
            }
        }
    }
}
