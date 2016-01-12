//
//  NSMutableAttributedString.swift
//  shoppin
//
//  Created by ischuetz on 12/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {

    func setTextColor(color: UIColor) {
        addAttributes([NSForegroundColorAttributeName: UIColor.blackColor()], range: string.fullRange)
    }
}
