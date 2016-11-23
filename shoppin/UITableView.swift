//
//  UITableView.swift
//  shoppin
//
//  Created by ischuetz on 01/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension UITableView {
    
    var inset: UIEdgeInsets {
        set {
            self.contentInset = newValue
            
            //TODO do we need this
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        get {
            return self.contentInset
        }
    }
    
    var topOffset: CGFloat {
        set {
            self.contentOffset = CGPoint(x: contentOffset.x, y: newValue)
        }
        get {
            return self.contentOffset.y
        }
    }
    
    var topInset: CGFloat {
        set {
            self.contentInset = UIEdgeInsetsMake(newValue, contentInset.left, contentInset.bottom, contentInset.right)
        }
        get {
            return self.contentInset.top
        }
    }

    var bottomInset: CGFloat {
        set {
            self.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, newValue, contentInset.right)
        }
        get {
            return self.contentInset.bottom
        }
    }
    
    func absoluteRow(_ indexPath: IndexPath) -> Int {
        var absRow = (indexPath as NSIndexPath).row
        for section in 0..<(indexPath as NSIndexPath).section {
            absRow += self.numberOfRows(inSection: section)
        }
        return absRow
    }
    
    func wrapUpdates(_ function: VoidFunction) {
        self.beginUpdates()
        function()
        self.endUpdates()
    }
    
    func wrapAnimationAndUpdates(_ function: VoidFunction, onComplete: @escaping VoidFunction) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            onComplete()
        }
        self.beginUpdates()
        function()
        self.endUpdates()
        CATransaction.commit()
    }
}
