//
//  UIView.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension UIView {
   
    func centerInParent(constantX:Float = 0, constantY:Float = 0) {
        self.centerXInParent(constantX)
        self.centerYInParent(constantY)
    }
    
    func centerYInView(view: UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: CGFloat(constant))
        view.addConstraint(c)
        return c
    }

    func centerXInView(view: UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: CGFloat(constant))
        view.addConstraint(c)
        return c
    }
    
    func centerYInParent(constant:Float = 0) -> NSLayoutConstraint {
        return centerYInView(superview!, constant: constant)
    }
    
    func centerXInParent(constant:Float = 0) -> NSLayoutConstraint {
        return centerXInView(superview!, constant: constant)
    }
    
    func positionBelowView(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func alignTop(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }

    func alignLeft(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func alignRight(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func alignBottom(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func widthConstraint(width: CGFloat) {
        let c = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: width)
        self.addConstraint(c)
    }
    
    func heightConstraint(height: CGFloat) {
        let c = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: height)
        self.addConstraint(c)
    }
    
    func matchSize(view: UIView) {
        self.superview?.addConstraints([
            NSLayoutConstraint.matchWidth(view: self, otherView: view),
            NSLayoutConstraint.matchHeight(view: self, otherView: view)])
    }
    
    func fillSuperview() {
        if let superview = superview {
            fill(superview)
        } else {
            print("Warn: call fillSuperview but there's no superview")
        }
    }

    func fillSuperviewWidth(leftConstant: Float = 0, rightConstant: Float = 0) {
        if let superview = superview {
            fillWidth(superview, leftConstant: leftConstant, rightConstant: rightConstant)
        } else {
            print("Warn: call fillSuperviewWidth but there's no superview")
        }
    }
    
    func fillSuperviewHeight() {
        if let superview = superview {
            fillHeight(superview)
        } else {
            print("Warn: call fillSuperviewHeight but there's no superview")
        }
    }
    
    func fillWidth(view: UIView, leftConstant: Float = 0, rightConstant: Float = 0) {
        alignLeft(view, constant: leftConstant)
        alignRight(view, constant: rightConstant)
    }
    
    func fillHeight(view: UIView) {
        alignTop(view)
        alignBottom(view)
    }
    
    func fill(view: UIView) {
        alignTop(view)
        alignLeft(view)
        alignRight(view)
        alignBottom(view)
    }
    
    func addSubviewFill(view: UIView) {
        addSubview(view)
        fill(view)
        layoutIfNeeded()
//        view.fillSuperview()
    }
    
    /**
    Toggles a semi-transparent, blocking progress indicator overlay on this view
    */
    func defaultProgressVisible(visible: Bool = false) {
        if visible {
            if self.viewWithTag(ViewTags.GlobalActivityIndicator) == nil {
                let view = UIView(frame: self.bounds)
                view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
                view.tag = ViewTags.GlobalActivityIndicator
                
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
                let size: CGFloat = 50
                let sizeH: CGFloat = size/2
                activityIndicator.frame = CGRect(x: self.frame.width / 2 - sizeH, y: self.frame.height / 2 - sizeH, width: size, height: size)
                activityIndicator.startAnimating()
                
                view.addSubview(activityIndicator)
                self.addSubview(view)
                self.bringSubviewToFront(view)
            }
        } else {
            self.viewWithTag(ViewTags.GlobalActivityIndicator)?.removeFromSuperview()
        }
    }
    
    func removeSubviews() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
    // src http://stackoverflow.com/a/32042439/930450
    class func imageWithView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0)
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    func setHiddenAnimated(hidden: Bool) {
        if hidden != self.hidden {
            self.hidden = false
            alpha = hidden ? 1 : 0
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                self?.alpha = hidden ? 0 : 1
                }) {[weak self] complete in
                    self?.hidden = hidden
            }
        }
    }
    
    func rotate(degrees: Double) {
        transform = CGAffineTransformMakeRotation(CGFloat(degrees * M_PI / Double(180)))
    }
    
    // MARK: - Borders
    // Add borders using layers. Src: http://stackoverflow.com/a/30764398/930450
    
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        border.frame = CGRectMake(0, 0, self.frame.size.width, width)
        self.layer.addSublayer(border)
    }
    
    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        border.frame = CGRectMake(self.frame.size.width - width, 0, width, self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        border.frame = CGRectMake(0, self.bounds.size.height - width, self.bounds.size.width, width)
        self.layer.addSublayer(border)
    }
    
    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        border.frame = CGRectMake(0, 0, width, self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    func addBorderWithYOffset(color: UIColor, width: CGFloat, offset: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.CGColor
        border.frame = CGRectMake(0, offset - width, self.bounds.size.width, width)
        self.layer.addSublayer(border)
    }
    
    func scaleUpAndDown() {
        UIView.animateWithDuration(0.15, animations: {[weak self] in
            self?.transform = CGAffineTransformMakeScale(1.2, 1.2)
        }, completion: {[weak self] finished in
            UIView.animateWithDuration(0.15, animations: {[weak self] in
                self?.transform = CGAffineTransformMakeScale(1, 1)
            })
        })
    }
}
