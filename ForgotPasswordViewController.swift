//
//  ForgotPasswordViewController.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers

protocol ForgotPasswordDelegate: class {
    func onForgotPasswordSuccess()
}

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var emailField: UITextField!

    @IBOutlet weak var sendButton: UIButton!
    
    fileprivate var validator: Validator?

    weak var delegate: ForgotPasswordDelegate?
    
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.mainBGColor

        emailField.placeholder = trans("placeholder_enter_email")
        
        initValidator()
        prefill()
        
        layout()
        
        navigationItem.title = trans("title_forgot_password")
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ForgotPasswordViewController.handleTap(_:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }
    
    fileprivate func layout() {
        sendButton.layer.cornerRadius = DimensionsManager.userDetailsLogoutButtonRadius
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailField.becomeFirstResponder()
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    fileprivate func prefill() {
        if let email = self.email {
            emailField.text = email
            emailField.selectAll(nil)
        }
    }

    fileprivate func initValidator() {
        let validator = Validator()
        validator.registerField(emailField, rules: [EmailRule(message: trans("validation_email_format"))])
        self.validator = validator
    }
    
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == emailField {
            send()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func onSubmitTap(_ sender: UIButton) {
        send()
    }
    
    fileprivate func send() {
        
        guard validator != nil else { return }

        if let errors = validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            let currentFirstResponder = emailField.isFirstResponder ? emailField : nil
            view.endEditing(true)
            ValidationAlertCreator.present(errors, parent: root, firstResponder: currentFirstResponder)

        } else {
            if let email = emailField.text {
                progressVisible()
                Prov.userProvider.forgotPassword(email, successHandler{[weak self] in
                    self?.delegate?.onForgotPasswordSuccess()
                    })
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    deinit {
        logger.v("Deinit forgot password controller")
    }
}
