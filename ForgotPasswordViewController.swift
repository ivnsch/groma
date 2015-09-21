//
//  ForgotPasswordViewController.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol ForgotPasswordDelegate {
    func onForgotPasswordSuccess()
}

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    
    private var validator: Validator?

    var delegate: ForgotPasswordDelegate?
    
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.placeholder = "Enter your e-mail"
        
        initValidator()
        prefill()
    }
    
    private func prefill() {
        if let email = self.email {
            emailField.text = email
            emailField.selectAll(nil)
        }
    }

    private func initValidator() {
        let validator = Validator()
        validator.registerField(emailField, rules: [EmailRule(message: "validation_email_format")])
        self.validator = validator
    }
    
    @IBAction func onSubmitTap(sender: UIButton) {

        guard validator != nil else {return}

        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let email = emailField.text {
                progressVisible()
                Providers.userProvider.forgotPassword(email, successHandler{[weak self] in
                    self?.delegate?.onForgotPasswordSuccess()
                })
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
}
