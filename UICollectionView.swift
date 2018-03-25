//
//  UICollectionView.swift
//  groma
//
//  Created by Ivan Schuetz on 25.03.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

extension UICollectionView {

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
            contentInset = UIEdgeInsets(top: newValue, left: contentInset.left, bottom: contentInset.bottom, right: contentInset.right)
        }
        get {
            return contentInset.top
        }
    }

    var bottomInset: CGFloat {
        set {
            contentInset = UIEdgeInsets(top: contentInset.top, left: contentInset.left, bottom: newValue, right: contentInset.right)
        }
        get {
            return contentInset.bottom
        }
    }
}
