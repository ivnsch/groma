//
//  TutorialHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 11.08.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class TutorialHelper: NSObject, UIGestureRecognizerDelegate {

    fileprivate var tutorialView: TutorialView?
    fileprivate weak var parentView: UIView?

    init(parentView: UIView) {
        self.parentView = parentView
        super.init()

        addTouchRecognizers(parentView: parentView)
    }

    fileprivate func addTouchRecognizers(parentView: UIView) {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        parentView.addGestureRecognizer(tapRecognizer)

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        panRecognizer.cancelsTouchesInView = false
        //        tapRecognizer.delegate = self
        panRecognizer.delegate = self
        parentView.addGestureRecognizer(panRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func onTap(_ sender: UITapGestureRecognizer) {
        removeTutorialView()
    }

    @objc func onPan(_ sender: UIPanGestureRecognizer) {
        removeTutorialView()
    }

    fileprivate func removeTutorialView() {
        let tutorialView = self.tutorialView
        self.tutorialView = nil
        tutorialView?.remove()
    }

    // NOTE: For now this is very specific for "tap title to go back" tutorial - if more tutorials are needed
    // we should pass here a list of spec data structure (rects, text)
    func show(topBar: ListTopBarView) {
        guard let parentView = parentView else {
            logger.e("Invalid state: No parent view", .ui)
            return
        }

        guard (PreferencesManager.hasNotSeen(.showedTapTitleToGoBack)) else {
            logger.v("Already saw tutorial", .ui)
            return
        }

        let tutorialView = TutorialView()
        tutorialView.addTo(view: parentView)
        let leftRightInset: CGFloat = -60
        let topBottomInset: CGFloat = -10
        tutorialView.hole(frame: parentView.convert(topBar.titleLabelFrame, to: parentView)
            .insetBy(dx: leftRightInset, dy: topBottomInset, dw: leftRightInset, dh: topBottomInset))

        self.tutorialView = tutorialView

        PreferencesManager.markAsSeen(.showedTapTitleToGoBack)
    }

}
