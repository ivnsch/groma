//
//  NavigationTitleView.swift
//  shoppin
//
//  Created by ischuetz on 03.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol NavigationTitleViewDelegate {
    func onNavigationLabelTap()
}

class NavigationTitleView: UIView {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var labelText:String {
        set {
            self.label.text = newValue
        }
        get {
            return self.label.text!
        }
    }
    
    var textFieldText:String {
        set {
            self.textField.text = newValue
        }
        get {
            return self.textField.text!
        }
    }
    
    var delegate:NavigationTitleViewDelegate?
    
    override func awakeFromNib() {
        self.editMode = false
        
        self.isUserInteractionEnabled = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(NavigationTitleView.onTap))
        self.addGestureRecognizer(tapRecognizer)
        
        self.textField.placeholder = "New list name"
    }
    
    var editMode:Bool = false {
        didSet {
            self.label.isHidden = editMode
            self.textField.isHidden = !editMode
            
            self.textField.text = ""
            
            if editMode {
                self.textField.becomeFirstResponder()
            } else {
                self.textField.resignFirstResponder()
            }
        }
    }
    
    func onTap() {
        if !self.editMode {
            self.delegate?.onNavigationLabelTap()
        }
    }
}
