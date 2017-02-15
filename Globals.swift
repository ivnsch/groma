//
//  Globals.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

/// UIView animation with default theme duration
public func anim(f: @escaping () -> Void) {
    UIView.animate(withDuration: Theme.defaultAnimDuration) {
        f()
    }
}

/// Shorthand for conditional animation (with default theme duration)
public func animIf(_ animated: Bool, f: @escaping () -> Void) {
    if animated {
        UIView.animate(withDuration: Theme.defaultAnimDuration) {
            f()
        }
    } else {
        f()
    }
}
