//
//  ShoppingListItemCell.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class ShoppingListItemCell: UITableViewCell {

    @IBOutlet weak var itemNameLabel: UILabel!
    
    var itemName:String {
        get {
            return self.itemNameLabel.text!
        }
        set {
            self.itemNameLabel!.text = newValue
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.greenColor()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
}