//
//  EditListViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

struct EditListFormInput {
    let name: String
    let users: [SharedUserInput] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    init(name: String, users: [SharedUserInput] = []) {
        self.name = name
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(self.name), users: \(self.users)}"
    }
    
    func copy(name: String? = nil, users: [SharedUserInput]? = nil) -> EditListFormInput {
        return EditListFormInput(
            name: name ?? self.name,
            users: users ?? self.users
        )
    }
}

class EditListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {

    private var listProvider = ProviderFactory().listProvider
    
    @IBOutlet weak var listNameInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!

    private var listInputsValidator: Validator?
    private var userInputsValidator: Validator?
    
    var listFormInput = EditListFormInput(name: "", users: []) {
        didSet {
            self.initFieldsWithInput(self.listFormInput)
        }
    }
    
    var isEdit: Bool = false {
        didSet {
            if !self.isEdit {
                if let myEmail: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
                    self.listFormInput = self.listFormInput.copy(users: [SharedUserInput(email: myEmail)])
                }
            }
        }
    }
    
    func prefill(list: List) { // for edit list case
        self.listFormInput = EditListFormInput(name: list.name, users: list.users.map{SharedUserInput(email: $0.email)})
    }
    
    // Note, optionals because called from didSet which can be called before the outlets are initialized
    private func initFieldsWithInput(listFormInput: EditListFormInput) {
        if let listNameInputField = self.listNameInputField {
            listNameInputField.text = self.listFormInput.name
        }
        if let tableView = self.usersTableView {
            tableView.reloadData()
        }
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.listNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])

        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [MinLengthRule(length: 1, message: "validation_user_input_not_empty")])

        self.listInputsValidator = listInputsValidator
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usersTableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: "listCell")
        
        self.initFieldsWithInput(self.listFormInput)
        
        self.initValidator()
    }

    @IBAction func onDoneTap(sender: UIBarButtonItem) {

        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
   
        self.validateInputs(self.listInputsValidator) {[weak self] in
            
            if let listName = self!.listNameInputField.text {
                
                // FIXME code smell - not using listFormInput for the listName, are we using listFormInput correctly? Do we actually need listFormInput? Structure differently?
                let listInput = ListInput(uuid: NSUUID().UUIDString, name: listName, users: self!.listFormInput.users)
                
                self!.progressVisible(true)
                
                if self!.isEdit {
                    self!.listProvider.update(listInput, self!.successHandler{list in
                        self!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                        })
                } else {
                    // FIXME redundancy users empty array and shared users
                    let listWithSharedUsers = ListWithSharedUsersInput(list: List(uuid: NSUUID().UUIDString, name: listInput.name, listItems: [], users: []), users: listInput.users)
                    self!.listProvider.add(listWithSharedUsers, self!.successHandler{list in
                        self!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
                
            } else {
                print("TODO validation onDoneTap")
            }
        }
    }
    
    private func validateInputs(validator: Validator?, onValid: () -> ()) {
        
        guard validator != nil else {return}

        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            onValid()
        }
    }
    
    @IBAction func onCloseTap(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onAddUserTap(sender: UIButton) {
        self.validateInputs(self.userInputsValidator) {[weak self] in
            if let input = self!.addUserInputField.text {
                // TODO do later a verification here if email exists in the server
                self!.listFormInput = self!.listFormInput.copy(users: self!.listFormInput.users + [SharedUserInput(email: input)])
                self!.usersTableView?.reloadData()
                self!.addUserInputField.text = ""
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listFormInput.users.count ?? 0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) 
        
        let userInput = self.listFormInput.users[indexPath.row]
        cell.textLabel?.text = userInput.email
    
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
            
        if editingStyle == .Delete {
            
            self.usersTableView.wrapUpdates {
                var users = self.listFormInput.users
                users.removeAtIndex(indexPath.row)
                self.listFormInput = self.listFormInput.copy(users: users)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        // TODO
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.addUserInputField.resignFirstResponder() // hide keyboard
    }
}
