//
//  SelectQuantifiableCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 07/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class SelectQuantifiableCell: UITableViewCell, QuantityViewDelegate, SwipeToIncrementHelperDelegate {

    @IBOutlet weak var baseLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var quantityView: QuantityView!
    
    var quantifiableProduct: QuantifiableProduct? {
        didSet {
            if let quantifiableProduct = quantifiableProduct {
                baseLabel.text = quantifiableProduct.baseQuantity.quantityString
                unitLabel.text = quantifiableProduct.unit.id == .none ? "" : quantifiableProduct.unit.name
                quantityView.quantity = 1
                
            } else {
                baseLabel.text = ""
                unitLabel.text = ""
                quantityView.quantity = 0
            }
        }
    }
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?

    override func awakeFromNib() {
        super.awakeFromNib()
        quantityView.delegate = self
        
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: contentView)
        swipeToIncrementHelper?.delegate = self
    }
    
    var quantity: Float {
        return quantityView.quantity
    }
    
    func onRequestUpdateQuantity(_ delta: Float) {
        quantityView.quantity += delta
    }
    
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return quantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        quantityView.quantity = quantity
    }
    
    func onQuantityInput(_ quantity: Float) {
        quantityView.quantity = quantity // not sure this is necessary as this method is called after input view changes it's quantity
    }
    
    var swipeToIncrementEnabled: Bool {
        return true
    }
    
    func onFinishSwipe() {
        // do nothing
    }
}
