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

    static func create(_ errors: ValidatorDictionary<ValidationError>) -> UIAlertController {
        let errorMessages = errors.map {$0.value.errorMessage}
        
        let alert: UIAlertController = UIAlertController(title: trans("popup_title_validation_failed"), message: ValidationErrorMsgBuilder.errorMsg(errorMessages), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: trans("popup_button_ok"), style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}
