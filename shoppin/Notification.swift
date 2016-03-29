//
//  Notification.swift
//  shoppin
//
//  Created by ischuetz on 29/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

enum Notification: String {
    case ListRemoved = "ListRemoved"
    
    static func send(notification: Notification, dict: [String: AnyObject]) {
        NSNotificationCenter.defaultCenter().postNotificationName(notification.rawValue, object: nil, userInfo: dict)
    }
}

struct NotificationKey {
    static let list = "list"
}
