//
//  ValidationErrorMsgBuilder.swift
//  shoppin
//
//  Created by ischuetz on 26/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

struct ValidationErrorMsgBuilder {

    static func errorMsg(errors: [UITextField: ValidationError]) -> String {
        return errors.reduce("") {str, error in
            str + error.1.errorMessage + "\n"
        }
    }
}
