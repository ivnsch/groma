//
//  TodoListItemsEditBottomView.swift
//  shoppin
//
//  Created by ischuetz on 29/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol TodoListItemsEditBottomViewDelegate {
    func onExpandSections(expand: Bool)
}


class TodoListItemsEditBottomView: UIView, ExpandCollapseButtonDelegate {

    @IBOutlet weak var todoPriceLabel: UILabel!
    @IBOutlet weak var cartPriceLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!

    @IBOutlet weak var expandCollapseButton: ExpandCollapseButton!
    
    @IBOutlet weak var pricesRightConstraint: NSLayoutConstraint!

    var delegate: TodoListItemsEditBottomViewDelegate?
    
    func setTotalPrice(totalPrice: Float) {
        if let totalPriceLabel = totalPriceLabel {
            totalPriceLabel.text = totalPrice.toLocalCurrencyString()
        } else {
            QL3("Outlets not set, can't set price")
        }
    }
    
    var expandCollapseButtonExpanded: Bool {
        set {
            expandCollapseButton.expanded = newValue
        }
        get {
            return expandCollapseButton.expanded
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expandCollapseButton.delegate = self
    }
    
    // MARK: - ExpandCollapseButtonDelegate
    
    func onExpandButton(expanded: Bool) {
        delegate?.onExpandSections(expanded)
    }
}