//
//  ManageItemsUnitsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers


protocol ManageItemsUnitsControllerDelegate: class {
    var topControllerConfig: ManageDatabaseTopControllerConfig {get}
    
}

class ManageItemsUnitsController: UITableViewController, SearchableTextController {
    
    fileprivate var units: Results<Providers.Unit>?
    
    fileprivate var topEditUnitControllerManager: ExpandableTopViewController<EditNameButtonController>?
    
    weak var delegate: ManageItemsControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load()
        
        if let delegate = delegate {
            topEditUnitControllerManager = initSimpleInputControllerManager(config: delegate.topControllerConfig)
        } else {
            logger.e("Can't initialize top controller: No delegate")
        }
    }
    
    fileprivate func load() {
        Prov.unitProvider.units(buyable: nil, successHandler {[weak self] units in
            self?.units = units
        })
    }
    
    fileprivate func initSimpleInputControllerManager(config: ManageDatabaseTopControllerConfig) -> ExpandableTopViewController<EditNameButtonController> {
        let manager: ExpandableTopViewController<EditNameButtonController> = ExpandableTopViewController(top: config.top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: config.animateInset, parentViewController: config.parentController, tableView: tableView) {[weak self] _ in
            let controller = EditNameButtonController()
            controller.delegate = self
            return controller
        }
        manager.delegate = config.delegate
        return manager
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return units?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let units = units else {logger.e("No units"); return UITableViewCell()}
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ManageItemsUnitCell
        
        cell.config(unit: units[indexPath.row], filter: delegate?.currentFilter)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.ingredientsCellHeight
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            guard let units = units else {logger.e("No units"); return}
            
            // Removing base is equivalent to remove products with base, base doesn't exist outside of products.
            Prov.unitProvider.delete(name: units[indexPath.row].name, notificationToken: nil, successHandler{[weak self] in
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let units = units else {logger.e("No units"); return}
        let unit = units[indexPath.row]
        
        topEditUnitControllerManager?.expand(true)
        
        topEditUnitControllerManager?.controller?.config(
            mode: .standalone,
        
        prefillData: EditNameButtonViewInputs(
            name: unit.name,
            buttonSelected: unit.buyable),
        
        settings: EditNameButtonViewSettings(
            namePlaceholder: trans("placeholder_name"),
            nameEmptyValidationMessage: trans("validation_name_not_empty"),
            buttonTitle: trans("button_title_buyable")
        ), editingObj: unit)
        
        //        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    // MARK: - SearchableTextController
    
    func filterItems(str: String) {
        Prov.unitProvider.unitsContainingText(str, successHandler {[weak self] units in
            self?.units = units
            self?.tableView.reloadData()
        })
    }
}



// MARK: - EditNameButtonDelegate

extension ManageItemsUnitsController: EditNameButtonDelegate {
    
    func onSubmitNameButtonInput(result: EditNameButtonResult, editingObj: Any?) {
        guard let editingUnit = editingObj as? Providers.Unit else {logger.e("Invalid state: no editing obj or wrong type: \(String(describing: editingObj))"); return}
        
        Prov.unitProvider.update(unit: editingUnit, name: result.inputs.name, buyable: result.inputs.buttonSelected, successHandler{[weak self] in
            self?.topEditUnitControllerManager?.expand(false)
            self?.tableView.reloadData()
        })
    }

    func onEditNameButtonNavigateToNextTextField() {
        // Do nothing - no next text field in top controller
    }
}
