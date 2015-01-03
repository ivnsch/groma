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
        
        self.userInteractionEnabled = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTap")
        self.addGestureRecognizer(tapRecognizer)
    }
    
    var editMode:Bool = false {
        didSet {
            self.label.hidden = editMode
            self.textField.hidden = !editMode
            
            self.textField.text = ""
            
            if editMode {
                self.textField.becomeFirstResponder()
            }
        }
    }
    
    func onTap() {
        if !self.editMode {
            self.delegate?.onNavigationLabelTap()
        }
    }
}
