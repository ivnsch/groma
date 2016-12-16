//
//  EditableChoiceModal.swift
//  shoppin
//
//  Created by ischuetz on 07/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class EditableChoiceModal: UIViewController, UIScrollViewDelegate {
    
    fileprivate var tableViewController: EditablePlainTableViewController?
    
    var list: List?
    
    var onDonePress: (() -> ())?
    
    var onAddItemFunc: ((String) -> ())?
    
    @IBOutlet weak var participantInputField: UITextField!
    
    @IBAction func onDonePress(_ sender: UIBarButtonItem) {
        self.onDonePress?()
    }
    
    var listItems: [EditablePlainTableViewControllerModel<DBSharedUser>]? {
        set {
            if let listItems = newValue, let tableViewController = self.tableViewController {
                tableViewController.listItems = listItems
            }
        }
        get {
            return self.tableViewController?.listItems
        }
    }

    func addItem(_ item: EditablePlainTableViewControllerModel<DBSharedUser>) {
        self.tableViewController?.addItem(item)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueName = segue.identifier
        if segueName == "tableViewControllerSegue" {
            self.tableViewController = segue.destination as? EditablePlainTableViewController
            self.tableViewController?.scrollViewDelegate = self
        }
    }
    
    
    // TODO rename add item this is a library candidate
    @IBAction func onAddParticipantPress(_ sender: UIButton) {
        if let _ = self.list {
            
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hideKeyboard()
    }
    
    fileprivate func hideKeyboard() {
        self.participantInputField.resignFirstResponder()
    }
    
}
