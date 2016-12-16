//
//  PullToAddHelper.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

// TODO object oriented
class PullToAddHelper {

    // Creates default refresh control
    static func createPullToAdd(_ parentController: UIViewController) -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: parentController.view.frame.width, height: refreshControl.bounds.height))
        label.font = Fonts.fontForSizeCategory(40)
        label.textColor = Theme.grey
        label.text = trans("pull_to_add")
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        refreshControl.addSubview(label)
        return refreshControl
    }
}
