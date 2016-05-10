//
//  QuantityCell.swift
//  shoppin
//
//  Created by ischuetz on 23/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuantityCellDelegate: class {
    func onPlusTap(cell: QuantityCell, indexPath: NSIndexPath)
    func onMinusTap(cell: QuantityCell, indexPath: NSIndexPath)
}

class QuantityCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var indexPath: NSIndexPath?
    
    weak var delegate: QuantityCellDelegate?
    
    var name: String? {
        set {
           nameLabel.text = newValue
        }
        get {
            return nameLabel.text
        }
    }

    var quantity: String? {
        set {
            quantityLabel.text = newValue
        }
        get {
            return quantityLabel.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None
        
        backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func onPlusTap() {
        if let indexPath = indexPath {
            delegate?.onPlusTap(self, indexPath: indexPath)
        } else {
            print("Warn: QuantityCell: No indexpath")
        }
    }
    
    
    @IBAction func onMinusTap() {
        if let indexPath = indexPath {
            delegate?.onMinusTap(self, indexPath: indexPath)
        } else {
            print("Warn: QuantityCell: No indexpath")
        }
    }
}
