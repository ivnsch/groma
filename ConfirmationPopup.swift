//
//  ConfirmationPopup.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ConfirmationPopup {
    
    static func create(title title: String? = nil, message: String, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { alertAction in
            onOk?()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { alertAction in
            onCancel?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, controller: UIViewController, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) {
        let alert = create(title: title, message: message, onOk: onOk, onCancel: onCancel)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}
