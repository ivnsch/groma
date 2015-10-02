//
//  NSBundle.swift
//  shoppin
//
//  Created by ischuetz on 02/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension NSBundle {

    static func loadView(name: String, owner: AnyObject!) -> UIView? {
        return NSBundle.mainBundle().loadNibNamed(name, owner: owner, options: nil).first as? UIView
    }
}
