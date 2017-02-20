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
    // backgroundColor: Overrides parentController's view background color as background color of pull to add
    static func createPullToAdd(_ parentController: UIViewController, backgroundColor: UIColor? = nil) -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: parentController.view.frame.width, height: refreshControl.bounds.height))
        label.font = Fonts.fontForSizeCategory(40)
        label.textColor = Theme.grey
        label.text = trans("pull_to_add")
        label.textAlignment = .center
        label.backgroundColor = backgroundColor ?? parentController.view.backgroundColor
        refreshControl.addSubview(label)
        return refreshControl
    }
}
