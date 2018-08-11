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

    fileprivate var dummyTouchPointView: UIView?

    override init(customView: UIView) {
        super.init(customView: customView)
        sharedInit()
    }

    override init(message: String) {
        super.init(message: message)
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    /**
    * Workaround - library doesn't accept point. So we add a small invisible dummy view where the point is and remove when tooltip is dimisseed
    */
    func presentPointing(at point: CGPoint, in view: UIView, animated: Bool) {
        let dummyTouchPointView = UIView(size: CGSize(width: 1, height: 1), center: point)
        dummyTouchPointView.backgroundColor = UIColor.clear
        view.addSubview(dummyTouchPointView)
        self.dummyTouchPointView = dummyTouchPointView
        super.presentPointing(at: dummyTouchPointView, in: view, animated: animated)
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
        dummyTouchPointView?.removeFromSuperview()
        onDismiss?()
    }
}
