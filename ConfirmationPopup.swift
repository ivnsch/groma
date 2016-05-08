//
//  ConfirmationPopup.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ConfirmationPopup {
    
    static func create(title title: String? = nil, message: String, okTitle: String, cancelTitle: String, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: okTitle, style: UIAlertActionStyle.Default, handler: { alertAction in
            onOk?()
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel, handler: { alertAction in
            onCancel?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, okTitle: String = "Ok", cancelTitle: String = "Cancel", controller: UIViewController, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) {
        let alert = create(title: title, message: message, okTitle: okTitle, cancelTitle: cancelTitle, onOk: onOk, onCancel: onCancel)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}
