//
//  IntroPageView.swift
//  shoppin
//
//  Created by ischuetz on 02/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class IntroPageView: UIView {
    @IBOutlet weak var label: UILabel!

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    private var initialBottomConstraintConstant: CGFloat?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.font = Fonts.smallLight
        initialBottomConstraintConstant = bottomConstraint.constant
    }

    func setup(source: IntroMode, controller: UIViewController) {
        if source == .more {
            guard let tabBarHeight = controller.tabBarController?.tabBar.frame.height else {
                logger.e("No tabbar - can't adjust constraint")
                return
            }

            guard let initialBottomConstraintConstant = initialBottomConstraintConstant else {
                logger.e("No initialBottomConstraintConstant - can't adjust constraint")
                return
            }

            bottomConstraint.constant = initialBottomConstraintConstant - tabBarHeight
        }
    }
}
