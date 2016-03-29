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
    case LoginTokenExpired = "LoginTokenExpired"
    
    static func send(notification: Notification, dict: [String: AnyObject]? = nil) {
        NSNotificationCenter.defaultCenter().postNotificationName(notification.rawValue, object: nil, userInfo: dict)
    }
    
    static func subscribe(notification: Notification, selector: Selector, observer: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: notification.rawValue, object: nil)
    }
}

struct NotificationKey {
    static let list = "list"
}
