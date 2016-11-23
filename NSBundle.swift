//
//  NSBundle.swift
//  shoppin
//
//  Created by ischuetz on 02/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension Bundle {

    static func loadView(_ name: String, owner: AnyObject!) -> UIView? {
        return Bundle.main.loadNibNamed(name, owner: owner, options: nil)?.first as? UIView
    }
}
