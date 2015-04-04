//
//  DialogUtils.swift
//  shoppin
//
//  Created by ischuetz on 04/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class DialogUtils {
    
    class func confirmAlert(okTitle: String = "Ok", cancelTitle: String = "Cancel", title: String = "Confirm", msg: String? = nil, okAction: VoidFunction) {
        let alert = NSAlert()
        alert.addButtonWithTitle(okTitle)
        alert.addButtonWithTitle(cancelTitle)
        
        alert.messageText = title
        alert.informativeText = msg
        
        alert.alertStyle = .WarningAlertStyle
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            okAction()
        }
    }
    
}
