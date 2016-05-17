//
//  ConfirmationPopup.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class ConfirmationPopup {
    
    class func show(title title: String? = nil, message: String, window: NSWindow, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) {
        let alert = NSAlert()
        alert.addButtonWithTitle(trans("popup_button_ok"))
        alert.addButtonWithTitle(trans("popup_button_cancel"))
        alert.messageText = message
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        
        alert.beginSheetModalForWindow(window) {modalResponse in
            switch modalResponse {
            case NSAlertSecondButtonReturn:
                onCancel?()
            case NSAlertFirstButtonReturn:
                onOk?()
            case _:
                print("Invalid case: \(modalResponse)")
            }
        }
    }
}
