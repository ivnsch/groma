//
//  SelectIngredientQuantityController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class SelectIngredientQuantityController: UIViewController, SwipeToIncrementHelperDelegate {

    @IBOutlet weak var quantityView: QuantityView!
    @IBOutlet weak var quantityViewContainer: UIView!
    
    var onUIReady: (() -> Void)?
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        swipeToIncrementHelper = SwipeToIncrementHelper(view: quantityViewContainer)
        swipeToIncrementHelper?.delegate = self

        onUIReady?()
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return quantityView.quantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        quantityView.quantity = quantity
    }
    
    func onFinishSwipe() {
    }
    
    var swipeToIncrementEnabled: Bool {
        return true
    }
    
}
