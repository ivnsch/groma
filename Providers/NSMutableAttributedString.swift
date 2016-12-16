//
//  NSMutableAttributedString.swift
//  shoppin
//
//  Created by ischuetz on 12/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

public extension NSMutableAttributedString {

    public func setTextColor(_ color: UIColor) {
        addAttributes([NSForegroundColorAttributeName: UIColor.black], range: string.fullRange)
    }
}
