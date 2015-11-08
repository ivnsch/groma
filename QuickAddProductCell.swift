//
//  QuickAddProductCell.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuickAddProductCellDelegate {
    func onPlusTap(indexPath: NSIndexPath)
    func onMinusTap(indexPath: NSIndexPath)
}

class QuickAddProductCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var minusButton: UIButton?
    @IBOutlet weak var plusButton: UIButton?
    
    var indexPath: NSIndexPath?
    
    var delegate: QuickAddProductCellDelegate?
    
    var item: QuickAddProduct? {
        didSet {
            if let item = item {
                nameLabel?.text = item.product.name
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    @IBAction func onPlusTap(button: UIButton) {
        if let indexPath = indexPath {
            delegate?.onPlusTap(indexPath)
        } else {
            print("QuickAddProductCell: no indexPath")
        }
    }
    
    @IBAction func onMinusTap(button: UIButton) {
        if let indexPath = indexPath {
            delegate?.onMinusTap(indexPath)
        } else {
            print("QuickAddProductCell: no indexPath")
        }
    }
}
