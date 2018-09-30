//
//  ConfirmationPopup.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

class ConfirmationPopup {
    
    static func create(title: String? = nil, message: String, okTitle: String, cancelTitle: String, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: okTitle, style: UIAlertAction.Style.default, handler: { alertAction in
            onOk?()
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel, handler: { alertAction in
            onCancel?()
        }))
        return alert
    }
    
    static func show(title: String? = nil, message: String, okTitle: String = trans("popup_button_ok"), cancelTitle: String = trans("popup_button_cancel"), controller: UIViewController, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil, onCannotPresent: VoidFunction? = nil) {
        let alert = create(title: title, message: message, okTitle: okTitle, cancelTitle: cancelTitle, onOk: onOk, onCancel: onCancel)
        
        if controller.presentedViewController == nil {
            controller.present(alert, animated: true, completion: nil)
        } else {
            logger.w("Already showing a confirmation popup: \(String(describing: controller.presentedViewController)), skipping new one: title: \(String(describing: title)), message: \(message)")
            onCannotPresent?()
        }
    }
}
