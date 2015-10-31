//
//  TimerUtils.swift
//  shoppin
//
//  Created by ischuetz on 30/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

func delay(time: Double, f: VoidFunction) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delay, dispatch_get_main_queue()) {
        f()
    }
}