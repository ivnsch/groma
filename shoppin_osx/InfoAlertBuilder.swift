//
//  InfoAlertBuilder.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class InfoAlertBuilder {

    static func show(title title: String? = nil, message: String, window: NSWindow, onDismiss: VoidFunction? = nil) {
        let alert = NSAlert()
        alert.addButtonWithTitle("ok")
        alert.messageText = message
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.beginSheetModalForWindow(window) {modalResponse in
            onDismiss?()
        }
    }
}
