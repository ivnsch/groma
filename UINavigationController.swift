//
//  UINavigationController.swift
//  shoppin
//
//  Created by ischuetz on 04/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension UINavigationController {

    // Note this doesn't color the bar buttons - this has to be done in view controller with navigation item
    func setColors(backgroundColor: UIColor, textColor: UIColor) {
        navigationBar.backgroundColor = backgroundColor
        navigationBar.barTintColor = backgroundColor
        navigationBar.tintColor = textColor
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: textColor]
    }
}
