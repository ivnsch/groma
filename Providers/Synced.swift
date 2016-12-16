//
//  Synced.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// src: http://stackoverflow.com/a/24103086/930450
public func synced(_ lock: AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

public func syncedRet<T>(_ lock: AnyObject, closure: () -> T) -> T {
    objc_sync_enter(lock)
    let t = closure()
    objc_sync_exit(lock)
    return t
}
