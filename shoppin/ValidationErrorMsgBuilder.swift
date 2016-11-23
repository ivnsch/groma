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

    static func errorMsg(_ errors: [String]) -> String {
        return errors.reduce("") {str, errorMessage in
            str + errorMessage + "\n"
        }
    }
}
