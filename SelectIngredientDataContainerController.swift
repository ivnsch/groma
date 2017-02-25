//
//  SelectIngredientDataContainerController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class SelectIngredientDataContainerController: UIViewController {

    var selectDataController: SelectIngredientDataController!
    
    var onSelectDataControllerReadyBeforeDidLoad: ((SelectIngredientDataController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let selectDataController = UIStoryboard.selectIngredientDataController()
        
        onSelectDataControllerReadyBeforeDidLoad?(selectDataController)
        
        addChildViewControllerAndView(selectDataController)
        selectDataController.view.frame = view.bounds
        self.selectDataController = selectDataController
    }
}
