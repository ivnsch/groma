//
//  Validatable.swift
//  shoppin
//
//  Created by Ivan Schütz on 17/11/2016.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol ValidatableTextField: Validatable {
    func showValidationError()
    func clearValidationError()
}
