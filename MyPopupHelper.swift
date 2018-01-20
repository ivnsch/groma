//
//  MyPopupHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 20.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class MyPopupHelper {

    fileprivate static let contentFrame = CGRect(x: 100, y: 20, width: 340, height: 480)

    fileprivate static var swipeHelper: GenericSwipeHelper? // arc

    // Optional title: overrides default titles for `type`
    static func showPopup(parent: UIViewController, type: MyPopupDefaultContentType, title: String? = nil, message: String, okText: String = trans("popup_button_ok"), centerYOffset: CGFloat = 0, onOk: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {

        let contentController = MyPopupDefaultContentViewController()

        let popup = MyPopup(parent: parent.view, frame: parent.view.bounds)
        popup.backgroundAlpha = 0.3
        popup.cornerRadius = 6
        popup.contentView = contentController.view
        popup.contentView?.frame = contentFrame

        parent.addChildViewController(contentController)

        contentController.config(type: type, message: message)

        func onOkOrCancel() {
            contentController.removeFromParentViewController()
            popup.hideFall()
        }

        contentController.handleOkPress = {
            onOkOrCancel()
            onOk?()
        }

        contentController.handleCancelPress = {
            onOkOrCancel()
            onCancel?()
        }

        // After this totalDelta (up or down) the popup is dimissed
        let totalDeltaToDismiss: CGFloat = 100
        swipeHelper = GenericSwipeHelper(view: popup, delta: 20, orientation: .vertical, cancelTouches: true, onDelta: { delta, totalDelta in

            popup.contentView?.y += delta

            // Decrease content view alpha as it's moved up and down
            // -> map totalDelta 0...200 to alpha 1...0 (at >= 200 the alpha is 0)
            let normalizedTotalDelta = min(abs(totalDelta) / 200, 1)
            let alpha = 1 - normalizedTotalDelta
            popup.contentView?.alpha = alpha

        }, onEnded: { totalDelta in
            if abs(totalDelta) > totalDeltaToDismiss { // Past limit -> dismiss
                popup.hideFullFall(direction: totalDelta > 0 ? .down : .up, onFinish: {
                    contentController.removeFromParentViewController()
                    onCancel?()
                })
            } else { // Gesture stopped before limit -> return to original position
                popup.returnToOriginFall(onFinish: {
                })
            }
        })

        popup.showFall(centerYOffset: centerYOffset, onFinish: {
        })
    }
}
