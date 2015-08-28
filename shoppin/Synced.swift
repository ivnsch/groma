//
//  Synced.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// src: http://stackoverflow.com/a/24103086/930450
func synced(lock: AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}