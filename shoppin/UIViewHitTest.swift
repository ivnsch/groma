//
//  UIViewHitTest.swift
//  shoppin
//
//  Created by Ivan Schuetz on 04/03/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class UIViewHitTest: UIView {
    
    var isInArea: ((CGPoint) -> Bool)?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isInArea?(point) ?? true {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
}
