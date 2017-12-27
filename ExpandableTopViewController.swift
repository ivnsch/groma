//
//  ExpandableTopViewController.swift
//  shoppin
//
//  Created by ischuetz on 15/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@objc protocol ExpandableTopViewControllerDelegate: class {
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView)
    func onExpandableClose()
}

class ExpandableTopViewController<T: UIViewController>: NSObject {

    fileprivate let top: CGFloat
    var height: CGFloat // Note: this only takes effect the next time view is expanded
    fileprivate let animateTableViewInset: Bool
    fileprivate let openInset: CGFloat // extra table view inset while open (additionally to the view's height when expanded)
    fileprivate let closeInset: CGFloat // extra table view inset while closed (additionally to the view's height when expanded)
    fileprivate weak var parentController: UIViewController?
    weak var tableView: UITableView?
    fileprivate let controllerBuilder: (ExpandableTopViewController<T>) -> T // initialise lazily the controller
    
    fileprivate(set) var controller: T?
    fileprivate var overlay: UIView?
    
    fileprivate(set) var expanded: Bool = false

    fileprivate var blocked = false
    
    weak var delegate: ExpandableTopViewControllerDelegate?

    fileprivate(set) var topViewTopConstraint: NSLayoutConstraint?
    var onDidSetTopConstraint: ((NSLayoutConstraint) -> Void)? // TODO rename on onLayoutTopController

    init(top: CGFloat, height: CGFloat, animateTableViewInset: Bool = true, openInset: CGFloat = 0,
         closeInset: CGFloat = 0, parentViewController: UIViewController, tableView: UITableView,
         controllerBuilder: @escaping (ExpandableTopViewController<T>) -> T) {
        self.top = top
        self.height = height
        self.animateTableViewInset = animateTableViewInset
        self.openInset = openInset
        self.closeInset = closeInset
        self.parentController = parentViewController
        self.tableView = tableView
        self.controllerBuilder = controllerBuilder
    }


    fileprivate func initView(_ view: UIView, height: CGFloat) {
        
        if let parentController = parentController {

            view.translatesAutoresizingMaskIntoConstraints = false

            let topViewTopConstraint = view.topAnchor.constraint(equalTo: parentController.view.topAnchor, constant: top)
            topViewTopConstraint.isActive = true


            self.topViewTopConstraint = topViewTopConstraint

            view.leftAnchor.constraint(equalTo: parentController.view.leftAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: parentController.view.rightAnchor, constant: 0).isActive = true
            view.heightAnchor.constraint(equalToConstant: height).isActive = true

            parentController.view.layoutIfNeeded()

            onDidSetTopConstraint?(topViewTopConstraint)

            view.transform = view.transform.translatedBy(x: 0, y: -height / 2.0)
            view.transform = view.transform.scaledBy(x: 1, y: 0.0001) //0.0001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears


            view.layoutIfNeeded()

        } else {
            print("Warn: no parentController in ExpandableTopViewController.initView")
        }
    }
    
    fileprivate func createOverlay() -> UIView {
        let view = UIButton()
        view.backgroundColor = UIColor.black
        view.isUserInteractionEnabled = true
        view.alpha = 0
        view.addTarget(self, action: #selector(ExpandableTopViewController.onOverlayTap(_:)), for: .touchUpInside)
        return view
    }
    
    func toggleExpanded() {
        expanded = !expanded
        expand(expanded)
    }
    
    func expand(_ expanded: Bool, onFinish: (() -> Void)? = nil) {

        guard !blocked else {return}
        guard self.expanded != expanded else {return}

        blocked = true
        
        if let parentController = self.parentController, let tableView = self.tableView {
            
            if expanded {
                // create and add overlay
//                let overlayTop = openInset + height
//                let overlayTop = 64 + openInset // 64 -> below nav bar
                let overlayTop = top
                let overlay = createOverlay()
                // FIXME!!! no force unwrap for tableview parent - use ?
                // TODO!!!!!!!!!!!!!!!!! harcoded height 1200 as tableView.superview!.frame.height seems unreliable - returns a short height while at this point it should be higher (it's at least what the view debugger shows).
//                overlay.frame = CGRect(x: tableView.frame.origin.x, y: overlayTop, width: tableView.frame.width, height: tableView.superview!.frame.height)
                overlay.frame = CGRect(x: tableView.frame.origin.x, y: overlayTop, width: tableView.frame.width, height: 1200)
                parentController.view.insertSubview(overlay, aboveSubview: tableView)
                self.overlay = overlay
                
                
                // create and add view
                let controller = controllerBuilder(self)  // note: for now we don't use the controller only view
                let view = controller.view
                parentController.addChildViewControllerAndView(controller)
                self.initView(view!, height: height)
                self.controller = controller
                view?.clipsToBounds = false
                
                // self.view.bringSubviewToFront(floatingViews) TODO!
            }

            UIView.animate(withDuration: 0.2, animations: {[weak self] in
                
                if let weakSelf = self, let view = weakSelf.controller?.view {
                    
                    if expanded {
                        weakSelf.overlay?.alpha = Theme.topControllerOverlayAlpha
                    } else {
                        weakSelf.overlay?.alpha = 0
                    }

                    if !expanded {
                        view.transform = view.transform.translatedBy(x: 0, y: -view.frame.size.height / 2.0)
                        view.transform = view.transform.scaledBy(x: 1, y: expanded ? 1 : 0.0001)
                    } else {
                        view.transform = CGAffineTransform.identity
                    }

                    if weakSelf.animateTableViewInset {
                        let topInset = (expanded ? weakSelf.openInset : weakSelf.closeInset) + view.frame.height
                        //                    let bottomInset = weakSelf.navigationController?.tabBarController?.tabBar.frame.height // TODO !!?
//                        let bottomInset: CGFloat = 0
                        tableView.topInset = topInset
//                        tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
                        tableView.topOffset = -tableView.inset.top
                    }

                    weakSelf.delegate?.animationsForExpand(weakSelf.controller!, expand: expanded, view: view)
                    
                } else {
                    print("Warn: ExpandableTopViewController.animateTopView: no self or view")
                }
                
                }, completion: {[weak self] finished in
                    
                    if !expanded {
                        self?.controller?.removeFromParentViewControllerWithView()
                        self?.overlay?.removeFromSuperview()
                        self?.controller = nil
                        self?.overlay = nil
                    }
                    
                    self?.expanded = expanded
                    self?.blocked = false
                    
                    onFinish?()
            }) 
        }
        
    }
    
    @objc func onOverlayTap(_ sender: UIButton) {
        expand(false)
        delegate?.onExpandableClose()
    }
}
