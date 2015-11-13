//
//  CGSize.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension CGSize {
    func increase(dx: CGFloat, dy: CGFloat) -> CGSize {
        return CGSizeMake(width + dx, height + dy)
    }
}
