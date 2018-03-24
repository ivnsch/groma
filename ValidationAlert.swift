//
//  ValidationAlert.swift
//  shoppin
//
//  Created by ischuetz on 26/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import Providers

struct ValidationAlertCreator { // had some problems subclassing UIAlertController because convenience init etc. so using creator instead

    static func present(_ errors: ValidatorDictionary<ValidationError>, parent: UIViewController, firstResponder: UITextField? = nil) {
        let errorMessages = errors.map { $0.value.errorMessage }
        present(errorMessages, parent: parent, firstResponder: firstResponder)
    }

    static func present(_ errorMessages: [String], parent: UIViewController, firstResponder: UITextField? = nil) {
        func onOkOrCancel() {
            firstResponder?.becomeFirstResponder()
        }

        MyPopupHelper.showPopup(parent: parent, type: .warning, message: ValidationErrorMsgBuilder.errorMsg(errorMessages), centerYOffset: 0, onOk: {
            onOkOrCancel()
        }, onCancel: {
            onOkOrCancel()
        })
    }
}
