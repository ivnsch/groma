//
//  Notification.swift
//  shoppin
//
//  Created by ischuetz on 29/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public enum Notification: String {
    case InventoryRemoved = "InventoryRemoved"

    case LoginTokenExpired = "LoginTokenExpired"

    case ListInvitationAccepted = "ListInvitationAccepted"
    case InventoryInvitationAccepted = "InventoryInvitationAccepted"

    case ShowShouldUpdateAppDialog = "ShowShouldUpdateAppDialog"
    case ShowMustUpdateAppDialog = "ShowMustUpdateAppDialog"

    // For cases after we log out but don't know where the user is, so user controller can update screen in case it's active.
    // Currently used for must app update dialog
    case LogoutUI = "LogoutUI"
    
    // TODO maybe remove LogoutUI
    case Logout = "Logout"

    case realmSwapped = "RealmSwapped"

    case willClearAllData = "willClearAllData"
    
    public static func send(_ notification: Notification, dict: [String: AnyObject]? = nil) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: notification.rawValue), object: nil, userInfo: dict)
    }
    
    public static func subscribe(_ notification: Notification, selector: Selector, observer: AnyObject) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notification.rawValue), object: nil)
    }
}

public struct NotificationKey {
    public static let inventory = "inventory"
}
