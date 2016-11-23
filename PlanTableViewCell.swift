//
//  PlanTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 06/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit


protocol PlanTableViewCellDelegate: class {
    func onPlusTap(_ planItem: PlanItem, cell: PlanTableViewCell, row: Int)
    func onMinusTap(_ planItem: PlanItem, cell: PlanTableViewCell, row: Int)
}

class PlanTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityLeftLabel: UILabel!
    
    weak var delegate: PlanTableViewCellDelegate?
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onPlusTap(_ sender: UIButton) {
        if let planItem = planItem, let row = row {
            delegate?.onPlusTap(planItem, cell: self, row: row)
        } else {
            print("Error: No plan item")
        }
    }

    @IBAction func onMinusTap(_ sender: UIButton) {
        if let planItem = planItem, let row = row {
            delegate?.onMinusTap(planItem, cell: self, row: row)
        } else {
            print("Error: No plan item")
        }
    }
}
