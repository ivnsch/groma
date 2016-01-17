//
//  AsyncUtils.swift
//  shoppin
//
//  Created by ischuetz on 17/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

func background<T>(background: Void -> T, onFinish: T -> Void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        let t: T = background()
        dispatch_async(dispatch_get_main_queue(), {
            onFinish(t)
        })
    })
}
