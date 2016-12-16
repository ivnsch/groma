//
//  CGSize.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

public extension CGSize {
    public func increase(_ dx: CGFloat, dy: CGFloat) -> CGSize {
        return CGSize(width: width + dx, height: height + dy)
    }
}
