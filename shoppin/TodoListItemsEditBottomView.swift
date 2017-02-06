//
//  TodoListItemsEditBottomView.swift
//  shoppin
//
//  Created by ischuetz on 29/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol TodoListItemsEditBottomViewDelegate: class {
    func onExpandSections(_ expand: Bool)
}


class TodoListItemsEditBottomView: UIView, ExpandCollapseButtonDelegate {

    @IBOutlet weak var todoPriceLabel: UILabel!
    @IBOutlet weak var cartPriceLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!

    weak var delegate: TodoListItemsEditBottomViewDelegate?
    
    func setTotalPrice(_ totalPrice: Float) {
        if let totalPriceLabel = totalPriceLabel {
            totalPriceLabel.text = totalPrice.toLocalCurrencyString()
        } else {
            QL3("Outlets not set, can't set price")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - ExpandCollapseButtonDelegate
    
    func onExpandButton(_ expanded: Bool) {
        delegate?.onExpandSections(expanded)
    }
}
