//
//  EditableChoiceModal.swift
//  shoppin
//
//  Created by ischuetz on 07/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class EditableChoiceModal: UIViewController {
    
    private var tableViewController: EditablePlainTableViewController?
    
    var list: List?
    
    var onDonePress: (() -> ())?
    
    var onAddItemFunc: (String -> ())?
    
    @IBOutlet weak var participantInputField: UITextField!
    
    @IBAction func onDonePress(sender: UIBarButtonItem) {
        self.onDonePress?()
    }
    
    var listItems: [EditablePlainTableViewControllerModel<SharedUser>]? {
        set {
            if let listItems = self.listItems, tableViewController = self.tableViewController {
                tableViewController.listItems = listItems
            }
        }
        get {
            return self.tableViewController?.listItems
        }
    }

    func addItem(item: EditablePlainTableViewControllerModel<SharedUser>) {
        self.tableViewController?.addItem(item)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueName = segue.identifier
        if segueName == "tableViewControllerSegue" {
            self.tableViewController = segue.destinationViewController as? EditablePlainTableViewController
        }
    }
    
    
    // TODO rename add item this is a library candidate
    @IBAction func onAddParticipantPress(sender: UIButton) {
        if let list = self.list {
            
            if let input = participantInputField.text {
                
                self.onAddItemFunc?(input)
                
//                self.userProvider.users(list) {result in
//                    
//                    if let users = result.sucessResult {
//                        
//                        let models = users.map{user in return EditablePlainTableViewControllerModel(model: user, text: user.email)} // TODO show also somehow the provider in duplicate email case (unique in server is email + provider(fb, twitter, normal login, etc))
//                        if let tableViewController = self.tableViewController {
//                            tableViewController.listItems = models
//                        }
//                        
//                    } else {
//                        // TODO error handling!!
//                        println("Error retrieving list's users. List: \(list)")
//                    }
//                }
            }
        }
    }
}
