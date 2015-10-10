//
//  PlanTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 06/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit


protocol PlanTableViewCellDelegate {
    func onPlusTap(planItem: PlanItem, cell: PlanTableViewCell, row: Int)
    func onMinusTap(planItem: PlanItem, cell: PlanTableViewCell, row: Int)
}

class PlanTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityLeftLabel: UILabel!
    
    var delegate: PlanTableViewCellDelegate?
    var row: Int?
    
    var planItem: PlanItem? {
        didSet {
            if let planItem = planItem {
                nameLabel.text = planItem.product.name
                quantityLabel.text = "\(planItem.quantity)"
                quantityLeftLabel.text = "\(planItem.quantity - planItem.usedQuantity)"
            } else {
                print("Warning: set plan item to nil (why?)")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onPlusTap(sender: UIButton) {
        if let planItem = planItem, row = row {
            delegate?.onPlusTap(planItem, cell: self, row: row)
        } else {
            print("Error: No plan item")
        }
    }

    @IBAction func onMinusTap(sender: UIButton) {
        if let planItem = planItem, row = row {
            delegate?.onMinusTap(planItem, cell: self, row: row)
        } else {
            print("Error: No plan item")
        }
    }
}
