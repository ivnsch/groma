//
//  NSView.swift
//  shoppin
//
//  Created by ischuetz on 05/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSView {

    // MARK: - autolayout
    
    func centerInParent() {
        self.centerHorizontallyInParent()
        self.centerVerticallyInParent()
    }
    
    func centerVerticallyInParent() {
        self.superViewConstraintFunction {superview in
            superview.addConstraint(NSLayoutConstraint.verticalCenterConstraint(self, superview: superview))
        }
    }
    
    func centerHorizontallyInParent() {
        self.superViewConstraintFunction {superview in
            superview.addConstraint(NSLayoutConstraint.horizontalCenterConstraint(self, superview: superview))
        }
    }
   
    func removeAllConstraints() {
        self.removeConstraints(self.constraints)
    }
    
    private func superViewConstraintFunction(function: (superview: NSView) -> ()) {
        if let superview = self.superview {
            function(superview: superview)
        } else {
            print("Warning: trying to add superview constraint without a superview")
        }
    }
   
    func matchSize(view: NSView) {
        
        self.superview?.addConstraints([
            NSLayoutConstraint.matchWidth(view: self, otherView: view),
            NSLayoutConstraint.matchHeight(view: self, otherView: view)])
    }
    
    /**
    Toggles a semi-transparent, blocking progress indicator overlay on this view
    */
    func defaultProgressVisible(visible: Bool = false) {
        if visible {
            if self.viewWithTag(ViewTags.GlobalActivityIndicator) == nil {
                let view = TaggedView(frame: self.frame)
                view.tagReadWrite = ViewTags.GlobalActivityIndicator
                
                view.wantsLayer = true
                view.layer?.backgroundColor = NSColor.blackColor().colorWithAlphaComponent(0.2).CGColor
                
                let activityIndicator = NSProgressIndicator()
                activityIndicator.style = .SpinningStyle
                let size: CGFloat = 50
                let sizeH: CGFloat = size/2
                activityIndicator.frame = CGRect(x: self.frame.width / 2 - sizeH, y: self.frame.height / 2 - sizeH, width: size, height: size)
                activityIndicator.startAnimation(self)
                
                view.addSubview(activityIndicator)
                self.addSubview(view)
            }
        } else {
            self.viewWithTag(ViewTags.GlobalActivityIndicator)?.removeFromSuperview()
        }
    }
}
