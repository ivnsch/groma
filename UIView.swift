//
//  UIView.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

extension UIView {
   
    public func centerInParent(_ constantX:Float = 0, constantY:Float = 0) {
        _ = centerXInParent(constantX)
        _ = centerYInParent(constantY)
    }
    
    public func centerYInView(_ view: UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: CGFloat(constant))
        view.addConstraint(c)
        return c
    }

    public func centerXInView(_ view: UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: CGFloat(constant))
        view.addConstraint(c)
        return c
    }
    
    public func centerYInParent(_ constant:Float = 0) -> NSLayoutConstraint {
        return centerYInView(superview!, constant: constant)
    }
    
    public func centerXInParent(_ constant:Float = 0) -> NSLayoutConstraint {
        return centerXInView(superview!, constant: constant)
    }
    
    public func positionBelowView(_ view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    public func positionAboveView(_ view: UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    public func alignTop(_ view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }

    public func alignLeft(_ view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    public func alignRight(_ view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    public func alignBottom(_ view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    public func widthConstraint(_ width: CGFloat) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        self.addConstraint(c)
        return c
    }
    
    public func widthLessThanConstraint(_ width: CGFloat) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        self.addConstraint(c)
        return c
    }
    
    public func heightConstraint(_ height: CGFloat) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        self.addConstraint(c)
        return c
    }
    
    public func matchSize(_ view: UIView) {
        self.superview?.addConstraints([
            NSLayoutConstraint.matchWidth(view: self, otherView: view),
            NSLayoutConstraint.matchHeight(view: self, otherView: view)])
    }
    
    public func fillSuperview() {
        if let superview = superview {
            fill(superview)
        } else {
            print("Warn: call fillSuperview but there's no superview")
        }
    }

    public func fillSuperviewWidth(_ leftConstant: Float = 0, rightConstant: Float = 0) {
        if let superview = superview {
            fillWidth(superview, leftConstant: leftConstant, rightConstant: rightConstant)
        } else {
            print("Warn: call fillSuperviewWidth but there's no superview")
        }
    }
    
    public func fillSuperviewHeight() {
        if let superview = superview {
            fillHeight(superview)
        } else {
            print("Warn: call fillSuperviewHeight but there's no superview")
        }
    }
    
    public func fillWidth(_ view: UIView, leftConstant: Float = 0, rightConstant: Float = 0) {
        _ = alignLeft(view, constant: leftConstant)
        _ = alignRight(view, constant: rightConstant)
    }
    
    public func fillHeight(_ view: UIView) {
        _ = alignTop(view)
        _ = alignBottom(view)
    }
    
    public func fill(_ view: UIView) {
        _ = alignTop(view)
        _ = alignLeft(view)
        _ = alignRight(view)
        _ = alignBottom(view)
    }
    
    public func addSubviewFill(_ view: UIView) {
        addSubview(view)
        fill(view)
        layoutIfNeeded()
//        view.fillSuperview()
    }
    
    /**
    Toggles a semi-transparent, blocking progress indicator overlay on this view
    */
    public func defaultProgressVisible(_ visible: Bool = false) {
        if visible {
            if self.viewWithTag(ViewTags.GlobalActivityIndicator) == nil {
                let view = UIView(frame: self.bounds)
                view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                view.tag = ViewTags.GlobalActivityIndicator
                
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
                let size: CGFloat = 50
                let sizeH: CGFloat = size/2
                activityIndicator.frame = CGRect(x: self.frame.width / 2 - sizeH, y: self.frame.height / 2 - sizeH, width: size, height: size)
                activityIndicator.startAnimating()
                
                view.addSubview(activityIndicator)
                self.addSubview(view)
                self.bringSubview(toFront: view)
            }
        } else {
            self.viewWithTag(ViewTags.GlobalActivityIndicator)?.removeFromSuperview()
        }
    }
    
    public func removeSubviews() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
    // src http://stackoverflow.com/a/32042439/930450
    public class func imageWithView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    public func setHiddenAnimated(_ hidden: Bool) {
        if hidden != self.isHidden {
            self.isHidden = false
            alpha = hidden ? 1 : 0
            UIView.animate(withDuration: 0.3, animations: {[weak self] in
                self?.alpha = hidden ? 0 : 1
                }, completion: {[weak self] complete in
                    self?.isHidden = hidden
            }) 
        }
    }
    
    public func rotate(_ degrees: Double) {
        transform = transform.rotated(by: CGFloat(degrees.degreesToRadians))
    }
    
    // MARK: - Borders
    // Add borders using layers. Src: http://stackoverflow.com/a/30764398/930450
    
    public func addTopBorderWithColor(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    public func addRightBorderWithColor(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    public func addBottomBorderWithColor(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.bounds.size.height - width, width: self.bounds.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    public func addLeftBorderWithColor(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    public func addBorderWithYOffset(_ color: UIColor, width: CGFloat, offset: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        
        // FIXME! hack - self.bounds.size.width. Quick fix for full width in cells, in iPhone6+ the border not complete - because file in IB is for iPhone6 screen size and when we retrieve bounds the final size is not calculated yet.
        border.frame = CGRect(x: 0, y: offset - width, width: DimensionsManager.fullWidth, height: width)
//        border.frame = CGRectMake(0, offset - width, self.bounds.size.width, width)
        
        self.layer.addSublayer(border)
    }
    
    public func scaleUpAndDown(scale: CGFloat = 1.2, onFinish: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.15, animations: {[weak self] in
            self?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: {[weak self] finished in
            UIView.animate(withDuration: 0.15, animations: {[weak self] in
                self?.transform = CGAffineTransform(scaleX: 1, y: 1)
                onFinish?()
            })
        })
    }
    
    public func hasAncestor<T: UIView>(type: T.Type) -> Bool {
        guard let superview = superview else {return false}
        
        if (Swift.type(of: superview) == T.self) {
            return true
        }
        
        return superview.hasAncestor(type: type)
    }
    
    // MARK: - Convenience frame

    public var x: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            frame.origin.x = newValue
        }
    }
    
    public var y: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            frame.origin.y = newValue
        }
    }
    
    public var width: CGFloat {
        get {
            return frame.width
        }
        set {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: newValue, height: frame.height)
        }
    }
    
    public var height: CGFloat {
        get {
            return frame.height
        }
        set {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: newValue)
        }
    }
    
    convenience init(size: CGSize, center: CGPoint) {
        self.init(frame: CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height))
    }
    
    func copyView() -> UIView? {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as? UIView
    }
    
    // Changes the anchor of view without changing its position. Returns internal translation in pt
    func setAnchorWithoutMoving(_ anchor: CGPoint) -> CGPoint {
        let offsetAnchor = CGPoint(x: anchor.x - layer.anchorPoint.x, y: anchor.y - layer.anchorPoint.y)
        let offset = CGPoint(x: frame.width * offsetAnchor.x, y: frame.height * offsetAnchor.y)
        layer.anchorPoint = anchor
        transform = transform.translatedBy(x: offset.x, y: offset.y)
        return offset
    }
}
