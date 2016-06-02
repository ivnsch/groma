//
//  PullToAddHelper.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

// TODO object oriented
class PullToAddHelper {

    // Creates default refresh control
    static func createPullToAdd(parentController: UIViewController) -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        let label = UILabel(frame: CGRectMake(0, 0, parentController.view.frame.width, refreshControl.bounds.height))
        label.font = Fonts.fontForSizeCategory(15)
        label.textColor = Theme.grey
        label.text = trans("pull_to_add")
        label.textAlignment = .Center
        label.backgroundColor = UIColor.whiteColor()
        refreshControl.addSubview(label)
        return refreshControl
    }
}
