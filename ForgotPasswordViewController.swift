//
//  ForgotPasswordViewController.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

protocol ForgotPasswordDelegate: class {
    func onForgotPasswordSuccess()
}

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var emailField: UITextField!
    
    private var validator: Validator?

    weak var delegate: ForgotPasswordDelegate?
    
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.placeholder = trans("placeholder_enter_email")
        
        initValidator()
        prefill()
        
        navigationItem.title = trans("title_forgot_password")
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ForgotPasswordViewController.handleTap(_:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        emailField.becomeFirstResponder()
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    private func prefill() {
        if let email = self.email {
            emailField.text = email
            emailField.selectAll(nil)
        }
    }

    private func initValidator() {
        let validator = Validator()
        validator.registerField(emailField, rules: [EmailRule(message: trans("validation_email_format"))])
        self.validator = validator
    }
    
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == emailField {
            send()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func onSubmitTap(sender: UIButton) {
        send()
    }
    
    private func send() {
        
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
    
    deinit {
        QL1("Deinit forgot password controller")
    }
}
