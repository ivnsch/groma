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
            println("Warning: trying to add superview constraint without a superview")
        }
    }
   
}
