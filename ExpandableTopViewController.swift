//
//  ExpandableTopViewController.swift
//  shoppin
//
//  Created by ischuetz on 15/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

@objc protocol ExpandableTopViewControllerDelegate {
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView)
    func onExpandableClose()
}

class ExpandableTopViewController<T: UIViewController>: NSObject {

    private let top: CGFloat
    private let height: CGFloat
    private let animateTableViewInset: Bool
    private let openInset: CGFloat // extra table view inset while open (additionally to the view's height when expanded)
    private let closeInset: CGFloat // extra table view inset while closed (additionally to the view's height when expanded)
    private weak var parentController: UIViewController?
    weak var tableView: UITableView?
    private let controllerBuilder: Void -> T // initialise lazily the controller
    
    private(set) var controller: T?
    private var overlay: UIView?
    
    private(set) var expanded: Bool = false

    private var blocked = false
    
    var delegate: ExpandableTopViewControllerDelegate?
    
    init(top: CGFloat, height: CGFloat, animateTableViewInset: Bool = true, openInset: CGFloat = 0, closeInset: CGFloat = 0, parentViewController: UIViewController, tableView: UITableView, controllerBuilder: Void -> T) {
        self.top = top
        self.height = height
        self.animateTableViewInset = animateTableViewInset
        self.openInset = openInset
        self.closeInset = closeInset
        self.parentController = parentViewController
        self.tableView = tableView
        self.controllerBuilder = controllerBuilder
    }

    private func initView(view: UIView, height: CGFloat) {
        
        if let parentController = parentController {
            view.frame = CGRectMake(0, top, parentController.view.frame.width, height)
            
            // swift anchor
            view.layer.anchorPoint = CGPointMake(0.5, 0)
            view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
            
            let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
            view.transform = transform
            
            view.layoutIfNeeded()
            
        } else {
            print("Warn: no parentController in ExpandableTopViewController.initView")
        }
    }
    
    private func createOverlay() -> UIView {
        let view = UIButton()
        view.backgroundColor = UIColor.blackColor()
        view.userInteractionEnabled = true
        view.alpha = 0
        view.addTarget(self, action: "onOverlayTap:", forControlEvents: .TouchUpInside)
        return view
    }
    
    func toggleExpanded() {
        expanded = !expanded
        expand(expanded)
    }
    
    func expand(expanded: Bool) {

        guard !blocked else {return}
        guard self.expanded != expanded else {return}

        blocked = true
        
        if let parentController = self.parentController, tableView = self.tableView {
            
            if expanded {
                // create and add overlay
                let overlayTop = openInset + height
                let overlay = createOverlay()
                overlay.frame = CGRectMake(tableView.frame.origin.x, overlayTop, tableView.frame.width, tableView.frame.height)
                parentController.view.insertSubview(overlay, aboveSubview: tableView)
                self.overlay = overlay
                
                
                // create and add view
                let controller = controllerBuilder()  // note: for now we don't use the controller only view
                let view = controller.view
                self.initView(view, height: height)
                parentController.addChildViewControllerAndView(controller)
                self.controller = controller
                
                // self.view.bringSubviewToFront(floatingViews) TODO!
            }
            
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                
                if let weakSelf = self, view = weakSelf.controller?.view {
                    
                    if expanded {
                        weakSelf.overlay?.alpha = 0.2
                    } else {
                        weakSelf.overlay?.alpha = 0
                    }
                    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, expanded ? 1 : 0.001)
                    
                    if weakSelf.animateTableViewInset {
                        let topInset = (expanded ? weakSelf.openInset : weakSelf.closeInset) + view.frame.height
                        //                    let bottomInset = weakSelf.navigationController?.tabBarController?.tabBar.frame.height // TODO !!?
                        let bottomInset: CGFloat = 0
                        tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
                        tableView.topOffset = -tableView.inset.top
                    }

                    weakSelf.delegate?.animationsForExpand(weakSelf.controller!, expand: expanded, view: view)
                    
                } else {
                    print("Warn: ExpandableTopViewController.animateTopView: no self or view")
                }
                
                }) {[weak self] finished in
                    
                    if !expanded {
                        self?.controller?.removeFromParentViewControllerWithView()
                        self?.overlay?.removeFromSuperview()
                    }
                    
                    self?.expanded = expanded
                    self?.blocked = false
            }
        }
        
    }
    
    func onOverlayTap(sender: UIButton) {
        expand(false)
        delegate?.onExpandableClose()
    }
}
