//
//  MyTipPopup.swift
//  shoppin
//
//  Created by ischuetz on 03/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

class MyTipPopup: CMPopTipView, CMPopTipViewDelegate {

    var onDismiss: (() -> Void)?

    override init(customView: UIView) {
        super.init(customView: customView)
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func sharedInit() {
        borderColor = nil
        borderWidth = 0
        cornerRadius = 6
        hasShadow = false
        has3DStyle = false
        hasGradientBackground = false
        backgroundColor = Theme.blue
        dismissTapAnywhere = true
        disableTapToDismiss = false
        animation = CMPopTipAnimation.pop

        delegate = self
    }

    // MARK: - CMPopTipViewDelegate

    func popTipViewWasDismissed(byUser popTipView: CMPopTipView!) {
        onDismiss?()
    }
}
