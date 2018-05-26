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

    // There are optional because in IB we have this cell in different controllers and some don't have this
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var nameVerticalCenterConstraint: NSLayoutConstraint?
    
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
                
                // For now no subtitle, it makes the screen look overloaded. If we enable it we also need to animate properly on open/close
//                if let subtitle = model.subtitle {
//                    subtitleLabel?.text = subtitle
//                    subtitleLabel?.textColor = contrastingTextColor
//                    subtitleLabel?.hidden = false
//                    nameVerticalCenterConstraint?.constant = -10
//                } else {
                    subtitleLabel?.isHidden = true
                    nameVerticalCenterConstraint?.constant = 0
//                }
                
                
//                let showUserInfo = model.users.count > 0
                let showUserInfo = false
                
                usersIcon.isHidden = !showUserInfo
                userCountLabel.isHidden = !showUserInfo
                
//                if showUserInfo {
//                    userCountLabel.text = "\(model.users.count)"
//                    usersIcon.tintColor = contrastingTextColor
//                    userCountLabel.textColor = contrastingTextColor
//                } else {
//                    userCountLabel.text = ""
//                }
                
            }
        }
    }

    override func willTransition(to state: UITableViewCellStateMask) {
        super.willTransition(to: state)

        // Replace delete and reorder images
        DispatchQueue.main.async {
            if state.contains(UITableViewCellStateMask.showingEditControlMask) {
                for subview in self.subviews {
                    if String(describing: type(of: subview)).contains("UITableViewCellEditControl") {
                        (subview.subviews[safe: 1] as? UIImageView)?.image = #imageLiteral(resourceName: "sort_fav")
                        //                    subview.frame = CGRect(x: aSubView.frame.origin.x, y: aSubView.frame.origin.y, widthaSubView.frame.size.width, aSubView.frame.size.height - 10)
                    } else if String(describing: type(of: subview)).contains("UITableViewCellReorderControl") {
                        let firstImage = subview.subviews.first as? UIImageView
                        firstImage?.image = #imageLiteral(resourceName: "speechbubble")
                        firstImage?.frame = CGRect(x: subview.center.x - 15, y: subview.center.y - 15, width: 30, height: 30)
                    }
                }
            }
        }
    }
}
