//
//  ListTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework
import Providers

class ListTableViewCell: UITableViewCell {

    @IBOutlet weak var listName: UILabel!
    @IBOutlet weak var userCountLabel: UILabel!
    @IBOutlet weak var usersIcon: UIImageView!
    
    var list: List? {
        didSet {
            if let list = list {
                listName.text = list.name

                let c = list.color
                contentView.backgroundColor = c
                backgroundColor = c
                let v = UIView()
                v.backgroundColor = c
                selectedBackgroundView = v

                let contrastingTextColor = UIColor.white
                listName.textColor = contrastingTextColor
                
                let showUserInfo = list.users.count > 0
                
                usersIcon.isHidden = !showUserInfo
                userCountLabel.isHidden = !showUserInfo
                
                if showUserInfo {
                    userCountLabel.text = "\(list.users.count)"
                    usersIcon.tintColor = contrastingTextColor
                    userCountLabel.textColor = contrastingTextColor
                } else {
                    userCountLabel.text = ""
                }

            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
