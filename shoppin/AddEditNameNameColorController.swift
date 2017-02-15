//
//  AddEditNameNameColorController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 14/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import SwiftValidator


protocol AddEditNameNameColorControllerDelegate: class {
    func onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult)    
}

struct AddEditNameNameColorControllerInputs {
    let name: String // input for name field
    
    let nameColorName: String // input for name field of the name-color subcontroller
    let nameColorColor: UIColor  // input for color field of the name-color subcontroller
}


struct AddEditNameNameColorControllerSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
    
    let nameNameColorPlaceholder: String
    let nameNameColorEmptyValidationMessage: String
}


struct AddEditNameNameColorResult {
    let name: String
    let nameColorInputs: EditNameColorViewInputs
    let editingObj: Any
}

/// Note: for now this controller is assumed to be always standalone (see "mode" var in e.g. EditSingleInputController to see what this means)
class AddEditNameNameColorController: UIViewController, EditNameColorViewDelegate {

    fileprivate weak var nameController: EditSingleInputController!
    fileprivate weak var nameColorController: EditNameColorController!
    
    fileprivate var addButtonHelper: AddButtonHelper?

    fileprivate var editingObj: Any?

    var delegate: AddEditNameNameColorControllerDelegate?
    
    func config(prefillData: AddEditNameNameColorControllerInputs, settings: AddEditNameNameColorControllerSettings, editingObj: Any?) {
        guard nameController != nil else {QL4("Controllers not initialized yet"); return}
        
        nameController.config(mode: .embedded, prefillName: prefillData.name, settings: EditSingleInputControllerSettings(namePlaceholder: settings.namePlaceholder, nameEmptyValidationMessage: settings.nameEmptyValidationMessage))
        nameController.editingObj = editingObj
        
        nameColorController.config(mode: .embedded, prefillData: EditNameColorViewInputs(name: prefillData.nameColorName, color: UIColor.black), settings: EditNameColorViewSettings(namePlaceholder: settings.nameNameColorPlaceholder, nameEmptyValidationMessage: settings.nameNameColorEmptyValidationMessage))
        nameColorController.editingObj = editingObj
        nameColorController.delegate = self
        
        self.editingObj = editingObj
        
        nameController.focus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper = initAddButtonHelper() // parent controller not set yet in earlier lifecycle methods
        addButtonHelper?.addObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {QL4("No parentController"); return nil}
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {QL4("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = parentView.height + tabBarHeight
        let addButtonHelper = AddButtonHelper(parentView: parentView, overrideCenterY: overrideCenterY) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }
    
    // Submit doesn't return anything here because we asume this controller to be always in standalone mode.
    func submit() {
        guard let editingObj = editingObj else {QL4("No editing object"); return}
        guard nameController != nil else {QL4("Controllers not initialized yet"); return}
        
        guard let nameControllerResult = nameController.submit() else {QL4("Couldn't retrieve results"); return}
        guard let nameColorControllerResult = nameColorController.submit() else {QL4("Couldn't retrieve results"); return}
        
        var name: String?
        var nameErrors: ValidatorDictionary<ValidationError>?
        switch nameControllerResult {
        case .ok(let res): name = res
        case .err(let errors): nameErrors = errors
        }
        
        var nameColorRes: EditNameColorResult?
        var nameColorErrors: ValidatorDictionary<ValidationError>?
        switch nameColorControllerResult {
        case .ok(let res): nameColorRes = res
        case .err(let errors): nameColorErrors = errors
        }
        
        if let name = name, let nameColorRes = nameColorRes {
            delegate?.onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult(name: name, nameColorInputs: nameColorRes.inputs, editingObj: editingObj))
            
        } else {
            guard let allErrors = (nameErrors.fOrAny(nameColorErrors){$0 + $1}) else {QL4("Invalid state: there should be errors here!"); return}
            present(ValidationAlertCreator.create(allErrors), animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "nameControllerEmbed" {
            nameController = segue.destination as? EditSingleInputController
        } else if segue.identifier == "nameColorControllerEmbed" {
            nameColorController = segue.destination as? EditNameColorController
        }
    }
    
    // MARK: - EditNameColorViewDelegate
    
    func onSubmitNameColor(result: EditNameColorResult) {
        // Do nothing - we retrieve the data when this controller is submitted
    }
    
    var popupsParent: UIViewController? {
        return self.parent
    }
}
