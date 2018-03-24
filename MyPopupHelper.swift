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

    // Default popup with type
    // Optional title: overrides default titles for `type`
    static func showPopup(parent: UIViewController, type: MyPopupDefaultContentType, title: String? = nil, message: String, highlightRanges: [NSRange] = [], okText: String = trans("popup_button_ok"), centerYOffset: CGFloat = 0, maxMsgLines: Int? = nil, swipeEnabled: Bool = true, onOk: (() -> Void)? = nil, onCancel: (() -> Void)? = nil, onOkOrCancel: (() -> Void)? = nil) {

        let contentController = MyPopupDefaultContentViewController()
        _ = contentController.view // trigger view load
        contentController.config(type: type, title: title, message: message, highlightRanges: highlightRanges, maxMsgLines: maxMsgLines)

        let popup = createPopup(parent: parent)

        func onOkOrCancelLocal() {
            contentController.removeFromParentViewController()
            popup.hideFall()
            onOkOrCancel?()
        }

        contentController.handleOkPress = {
            onOkOrCancelLocal()
            onOk?()
        }

        contentController.handleCancelPress = {
            onOkOrCancelLocal()
            onCancel?()
        }

        showPopup(popup: popup, parent: parent, centerYOffset: centerYOffset, contentController: contentController, swipeEnabled: swipeEnabled, onDismissWithSwipe: {
            onCancel?()
        })
    }

    static func showCustomPopup(parent: UIViewController, centerYOffset: CGFloat = 0, contentController: UIViewController, swipeEnabled: Bool = true, useDefaultFrame: Bool = true, onDismissWithSwipe: (() -> Void)? = nil) -> MyPopup {
        let popup = createPopup(parent: parent)
        showPopup(popup: popup, parent: parent, contentController: contentController, swipeEnabled: swipeEnabled, useDefaultFrame: useDefaultFrame)
        return popup
    }

    static func showCustomPopupFrom(parent: UIViewController, centerYOffset: CGFloat = 0, contentController: UIViewController, swipeEnabled: Bool = true, useDefaultFrame: Bool = true, from: UIView? = nil) -> MyPopup {
        let popup = createPopup(parent: parent)
        showPopup(popup: popup, parent: parent, contentController: contentController, swipeEnabled: swipeEnabled, from: from, useDefaultFrame: useDefaultFrame)
        return popup
    }

    fileprivate static func createPopup(parent: UIViewController) -> MyPopup {
        let popup = MyPopup(parent: parent.view, frame: parent.view.bounds)
        return popup
    }

    // Optional title: overrides default titles for `type`
    fileprivate static func showPopup(popup: MyPopup, parent: UIViewController, centerYOffset: CGFloat = 0, contentController: UIViewController, swipeEnabled: Bool = true, from: UIView? = nil, useDefaultFrame: Bool = true, onDismissWithSwipe: (() -> Void)? = nil) {

        popup.backgroundAlpha = 0.3
        popup.cornerRadius = Theme.popupCornerRadius
        popup.contentView = contentController.view
        if useDefaultFrame {
            popup.contentView?.frame = contentFrame
        }

        parent.addChildViewController(contentController)
        contentController.viewWillAppear(false)

        // After this totalDelta (up or down) the popup is dimissed
        let totalDeltaToDismiss: CGFloat = 100

        if swipeEnabled {
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
                        onDismissWithSwipe?()
                    })
                } else { // Gesture stopped before limit -> return to original position
                    popup.returnToOriginFall(onFinish: {
                    })
                }
            })
        }

        if let from = from {
            popup.show(from: from)
        } else {
            popup.showFall(centerYOffset: centerYOffset, onFinish: {
            })
        }
    }
}
