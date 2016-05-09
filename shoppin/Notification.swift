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

    case ListInvitationAccepted = "ListInvitationAccepted"
    case InventoryInvitationAccepted = "InventoryInvitationAccepted"

    case ShowShouldUpdateAppDialog = "ShowShouldUpdateAppDialog"
    case ShowMustUpdateAppDialog = "ShowMustUpdateAppDialog"

    // For cases after we log out but don't know where the user is, so user controller can update screen in case it's active.
    // Currently used for must app update dialog
    case LogoutUI = "LogoutUI"
    
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
