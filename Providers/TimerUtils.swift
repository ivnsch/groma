//
//  TimerUtils.swift
//  shoppin
//
//  Created by ischuetz on 30/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public func delay(_ seconds: Double, f: @escaping VoidFunction) {
    let delay = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delay) {
        f()
    }
}

// Cancellable delay - named differently to avoid having to edit all the places where currently delay is used.
public func delayNew(_ seconds: Double, f: @escaping VoidFunction) -> DispatchWorkItem {
    let task = DispatchWorkItem {f()}
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds, execute: task)
    return task
}
