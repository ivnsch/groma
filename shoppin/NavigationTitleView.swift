//
//  NavigationTitleView.swift
//  shoppin
//
//  Created by ischuetz on 03.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

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
    
    override func awakeFromNib() {
        self.editMode = false
    }
    
    var editMode:Bool = false {
        didSet {
            self.label.hidden = editMode
            self.textField.hidden = !editMode
            
            self.textField.text = ""
        }
    }
}
