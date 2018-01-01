//
//  AddEditNameNameColorController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 14/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import SwiftValidator


protocol AddEditNameNameColorControllerDelegate: class {
    func onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult)    
}

struct AddEditNameNameColorControllerInputs {
    let name: String // input for name field
    let buttonSelected: Bool
    
    let nameColorName: String // input for name field of the name-color subcontroller
    let nameColorColor: UIColor  // input for color field of the name-color subcontroller
}


struct AddEditNameNameColorControllerSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
    let buttonTitle: String
    
    let nameNameColorPlaceholder: String
    let nameNameColorEmptyValidationMessage: String
}


struct AddEditNameNameColorResult {
    let name: String
    let buttonSelected: Bool
    let nameColorInputs: EditNameColorViewInputs
    let editingObj: Any
}

// TODO rename - now the first controller is name-button, not only "name". The reason is that item now has field "edible" which shows a button to toggle it next to the name.
/// Note: for now this controller is assumed to be always standalone (see "mode" var in e.g. EditSingleInputController to see what this means)
class AddEditNameNameColorController: UIViewController, EditNameColorViewDelegate, EditNameButtonDelegate {

    fileprivate weak var nameController: EditNameButtonController!
    fileprivate weak var nameColorController: EditNameColorController!
    
    fileprivate var addButtonHelper: AddButtonHelper?

    fileprivate var editingObj: Any?

    var delegate: AddEditNameNameColorControllerDelegate?
    
    func config(prefillData: AddEditNameNameColorControllerInputs, settings: AddEditNameNameColorControllerSettings, editingObj: Any?) {
        guard nameController != nil else {logger.e("Controllers not initialized yet"); return}
        
        nameController?.config(
            mode: .embedded(isLast: false),
            
            prefillData: EditNameButtonViewInputs(
                name: prefillData.name,
                buttonSelected: prefillData.buttonSelected),
            
            settings: EditNameButtonViewSettings(
                namePlaceholder: settings.namePlaceholder,
                nameEmptyValidationMessage: settings.nameEmptyValidationMessage,
                buttonTitle: settings.buttonTitle
        ), editingObj: editingObj)
        nameController.delegate = self

        nameColorController.config(mode: .embedded(isLast: true), prefillData: EditNameColorViewInputs(name: prefillData.nameColorName, color: prefillData.nameColorColor), settings: EditNameColorViewSettings(namePlaceholder: settings.nameNameColorPlaceholder, nameEmptyValidationMessage: settings.nameNameColorEmptyValidationMessage))
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
        guard let parentView = parent?.view else {logger.e("No parentController"); return nil}
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {logger.e("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = parentView.height + tabBarHeight
        let addButtonHelper = AddButtonHelper(parentView: parentView, overrideCenterY: overrideCenterY) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }
    
    // Submit doesn't return anything here because we asume this controller to be always in standalone mode.
    func submit() {
        guard let editingObj = editingObj else {logger.e("No editing object"); return}
        guard nameController != nil else {logger.e("Controllers not initialized yet"); return}
        
        guard let nameControllerResult = nameController.submit() else {logger.e("Couldn't retrieve results"); return}
        guard let nameColorControllerResult = nameColorController.submit() else {logger.e("Couldn't retrieve results"); return}
        
        var result: EditNameButtonResult?
        var nameErrors: ValidatorDictionary<ValidationError>?
        switch nameControllerResult {
        case .ok(let res): result = res
        case .err(let errors): nameErrors = errors
        }
        
        var nameColorRes: EditNameColorResult?
        var nameColorErrors: ValidatorDictionary<ValidationError>?
        switch nameColorControllerResult {
        case .ok(let res): nameColorRes = res
        case .err(let errors): nameColorErrors = errors
        }
        
        if let result = result, let nameColorRes = nameColorRes {
            delegate?.onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult(name: result.inputs.name, buttonSelected: result.inputs.buttonSelected, nameColorInputs: nameColorRes.inputs, editingObj: editingObj))
            
        } else {
            guard let allErrors = (nameErrors.fOrAny(nameColorErrors){$0 + $1}) else {logger.e("Invalid state: there should be errors here!"); return}
            present(ValidationAlertCreator.create(allErrors), animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "nameControllerEmbed" {
            nameController = segue.destination as? EditNameButtonController
        } else if segue.identifier == "nameColorControllerEmbed" {
            nameColorController = segue.destination as? EditNameColorController
        }
    }

    // MARK: - EditNameButtonDelegate

    func onSubmitNameButtonInput(result: EditNameButtonResult, editingObj: Any?) {
        // Do nothing - we retrieve the data when this controller is submitted
    }

    func onEditNameButtonNavigateToNextTextField() {
        nameColorController.focus()
    }

    // MARK: - EditNameColorViewDelegate

    func onSubmitNameColor(result: EditNameColorResult) {
        // Do nothing - we retrieve the data when this controller is submitted
    }
    
    var popupsParent: UIViewController? {
        return self.parent
    }
}
