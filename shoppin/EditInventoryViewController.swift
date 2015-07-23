//
//  EditInventoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

struct EditInventoryFormInput {
    let name: String
    let users: [SharedUserInput] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    init(name: String, users: [SharedUserInput] = []) {
        self.name = name
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(self.name), users: \(self.users)}"
    }
    
    func copy(name: String? = nil, users: [SharedUserInput]? = nil) -> EditInventoryFormInput {
        return EditInventoryFormInput(
            name: name ?? self.name,
            users: users ?? self.users
        )
    }
}

class EditInventoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    private var inventoryProvider = ProviderFactory().inventoryProvider
    
    @IBOutlet weak var inventoryNameInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!
    
    var inventoryFormInput = EditInventoryFormInput(name: "", users: []) {
        didSet {
            self.initFieldsWithInput(self.inventoryFormInput)
        }
    }
    
    var isEdit: Bool = false {
        didSet {
            if !self.isEdit {
                if let myEmail: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
                    self.inventoryFormInput = self.inventoryFormInput.copy(users: [SharedUserInput(email: myEmail)])
                }
            }
        }
    }
    
    func prefill(inventory: Inventory) { // for edit list case
        self.inventoryFormInput = EditInventoryFormInput(name: inventory.name, users: inventory.users.map{SharedUserInput(email: $0.email)})
    }
    
    // Note, optionals because called from didSet which can be called before the outlets are initialized
    private func initFieldsWithInput(inventoryFormInput: EditInventoryFormInput) {
        if let inventoryNameInputField = self.inventoryNameInputField {
            inventoryNameInputField.text = self.inventoryFormInput.name
        }
        if let tableView = self.usersTableView {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usersTableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: "listCell")
        
        self.initFieldsWithInput(self.inventoryFormInput)
    }
    
    @IBAction func onDoneTap(sender: UIBarButtonItem) {
        
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        let inventoryName = self.inventoryNameInputField.text
        
        let inventoryInput = InventoryInput(uuid: NSUUID().UUIDString, name: inventoryName, users: self.inventoryFormInput.users)
        
        self.progressVisible(true)
        
        if self.isEdit {
            self.inventoryProvider.updateInventory(inventoryInput, successHandler{list in
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            self.inventoryProvider.addInventory(inventoryInput, successHandler{list in
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    @IBAction func onCloseTap(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onAddUserTap(sender: UIButton) {
        let input: String = self.addUserInputField.text
        // TODO validate
        
        // TODO do later a verification here if email exists in the server
        self.inventoryFormInput = self.inventoryFormInput.copy(users: self.inventoryFormInput.users + [SharedUserInput(email: input)])
        self.usersTableView?.reloadData()
        self.addUserInputField.text = ""
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.inventoryFormInput.users.count ?? 0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! UITableViewCell
        
        let userInput = self.inventoryFormInput.users[indexPath.row]
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
                var users = self.inventoryFormInput.users
                users.removeAtIndex(indexPath.row)
                self.inventoryFormInput = self.inventoryFormInput.copy(users: users)
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