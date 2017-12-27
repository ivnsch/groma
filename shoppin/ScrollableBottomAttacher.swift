//
//  ScrollableBottomAttacher.swift
//  groma
//
//  Created by Ivan Schuetz on 15.12.17.
//  Copyright © 2017 Sevenmind. All rights reserved.
//

import UIKit
import Providers

class ScrollableBottomAttacher<T: UITableViewController> {

    fileprivate let animDuration: TimeInterval = 0.3
    fileprivate var topViewHeight: CGFloat = 0
    fileprivate let bottomViewHeight: CGFloat = 0

    fileprivate var spacingConstraint: NSLayoutConstraint!
    fileprivate var topViewTopConstraint: NSLayoutConstraint!
    fileprivate var tableViewConrollerHeightConstraint: NSLayoutConstraint!

    fileprivate var initTopConstant: CGFloat = 0
    fileprivate var targetTopConstantWhenExpanded: CGFloat {
        return initTopConstant - topViewHeight
    }

    fileprivate var spacingConstant: CGFloat = 50

    fileprivate let parent: UIViewController
    fileprivate let top: UIViewController
    let bottom: T

    fileprivate var lockShowTop = false
    fileprivate var lockHideTop = false

    fileprivate var availableTableViewHeight: CGFloat {
        let h = parent.view.frame.height - (topViewTopConstraint.constant + topViewHeight)
        return h
    }

    fileprivate var onExpandBottom: () -> Void

    init(parent: UIViewController, top: UIViewController, bottom: T,
         topViewTopConstraint: NSLayoutConstraint, onAddedSubview: () -> Void, onExpandBottom: @escaping () -> Void) {
        self.parent = parent
        self.top = top
        self.bottom = bottom
        self.topViewTopConstraint = topViewTopConstraint
        self.onExpandBottom = onExpandBottom

        parent.addChildViewControllerAndView(bottom)

        onAddedSubview()

        topViewHeight = top.view.height

        initTopConstant = topViewTopConstraint.constant

        attachBottom()
    }

    fileprivate func attachBottom() {
        bottom.view.translatesAutoresizingMaskIntoConstraints = false
        spacingConstraint = bottom.view.topAnchor.constraint(equalTo: top.view.bottomAnchor, constant: 0)
        spacingConstraint.isActive = true
        bottom.view.leftAnchor.constraint(equalTo: parent.view.leftAnchor, constant: 0).isActive = true
        bottom.view.rightAnchor.constraint(equalTo: parent.view.rightAnchor, constant: 0).isActive = true
        tableViewConrollerHeightConstraint = bottom.view.heightAnchor.constraint(equalToConstant: 0)
        tableViewConrollerHeightConstraint.isActive = true
        self.parent.view.layoutIfNeeded()

    }

    func hideTop(onFinish: @escaping () -> Void) {
        topViewTopConstraint.constant = targetTopConstantWhenExpanded
        tableViewConrollerHeightConstraint.constant = availableTableViewHeight
        UIView.animate(withDuration: animDuration, animations: {
            self.parent.view.layoutIfNeeded()
        }, completion: { finished in
//            self.spacingConstraint.constant = self.spacingConstant
//            self.topViewTopConstraint.constant = self.targetTopConstantWhenExpanded - self.spacingConstant
            self.topViewTopConstraint.constant = self.targetTopConstantWhenExpanded
            self.parent.view.layoutIfNeeded()
            onFinish()
            self.bottom.tableView.bounces = true
            self.onExpandBottom()
        })
    }

    func showTop(onFinish: @escaping () -> Void) {
        topViewTopConstraint.constant = initTopConstant
        spacingConstraint.constant = 0
        tableViewConrollerHeightConstraint.constant = availableTableViewHeight
        UIView.animate(withDuration: animDuration, animations: {
            self.parent.view.layoutIfNeeded()
        }, completion: { finished in
            onFinish()
            self.bottom.tableView.bounces = false
        })
    }

    func showBottom(onFinish: @escaping () -> Void) {
        tableViewConrollerHeightConstraint.constant = availableTableViewHeight
        UIView.animate(withDuration: animDuration, animations: {
            self.parent.view.layoutIfNeeded()
        }, completion: { finished in
            onFinish()
            self.bottom.tableView.bounces = true
        })
    }

    func removeBottom(onFinish: @escaping () -> Void) {
        topViewTopConstraint.constant = initTopConstant
        spacingConstraint.constant = 0
        tableViewConrollerHeightConstraint.constant = 0
        UIView.animate(withDuration: animDuration, animations: {
            self.parent.view.layoutIfNeeded()
        }, completion: { (finished) in
            onFinish()
            self.bottom.removeFromParentViewControllerWithView()
        })
    }
    
    func onBottomViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y

        let velocityY = scrollView.panGestureRecognizer.velocity(in: parent.view).y

        if velocityY > 0 && yOffset < -50 && !lockShowTop && !lockHideTop { // scroll down - show top
            lockShowTop = true
            showTop {
                self.lockShowTop = false
            }

            // scroll up - hide top
        } else if velocityY < 0 && topViewTopConstraint.constant == initTopConstant && !lockHideTop && !lockShowTop {
            lockHideTop = true
            hideTop {
                self.lockHideTop = false
            }
        }
    }
}
