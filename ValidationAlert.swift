//
//  ValidationAlert.swift
//  shoppin
//
//  Created by ischuetz on 26/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

struct ValidationAlertCreator { // had some problems subclassing UIAlertController because convenience init etc. so using creator instead

    static func create(errors: [UITextField: ValidationError]) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: trans("popup_title_validation_failed"), message: ValidationErrorMsgBuilder.errorMsg(errors), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: trans("popup_button_ok"), style: UIAlertActionStyle.Default, handler: nil))
        return alert
    }
}
