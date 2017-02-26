//
//  SelectIngredientQuantityController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class SelectIngredientQuantityController: UIViewController {

    @IBOutlet weak var quantityView: QuantityView!

    var onUIReady: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        onUIReady?()
    }
}
