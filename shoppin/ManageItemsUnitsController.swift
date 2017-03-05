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
import QorumLogs

protocol ManageItemsUnitsControllerDelegate: class {
    var topControllerConfig: ManageDatabaseTopControllerConfig {get}
    
}

class ManageItemsUnitsController: UITableViewController, SearchableTextController {
    
    fileprivate var units: Results<Providers.Unit>?
    
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSingleInputController>?
    
    weak var delegate: ManageItemsControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load()
        
        if let delegate = delegate {
            topEditSectionControllerManager = initSimpleInputControllerManager(config: delegate.topControllerConfig)
        } else {
            QL4("Can't initialize top controller: No delegate")
        }
    }
    
    fileprivate func load() {
        Prov.unitProvider.units(successHandler {[weak self] units in
            self?.units = units
        })
    }
    
    fileprivate func initSimpleInputControllerManager(config: ManageDatabaseTopControllerConfig) -> ExpandableTopViewController<EditSingleInputController> {
        let manager: ExpandableTopViewController<EditSingleInputController> = ExpandableTopViewController(top: config.top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: config.animateInset, parentViewController: config.parentController, tableView: tableView) {[weak self] in
            let controller = EditSingleInputController()
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
        
        guard let units = units else {QL4("No units"); return UITableViewCell()}
        
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
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            guard let units = units else {QL4("No units"); return}
            
            // Removing base is equivalent to remove products with base, base doesn't exist outside of products.
            Prov.unitProvider.delete(name: units[indexPath.row].name, successHandler{[weak self] in
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let units = units else {QL4("No units"); return}
        let unit = units[indexPath.row]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(mode: .standalone, prefillName: unit.name, settings: EditSingleInputControllerSettings(
            namePlaceholder: "placeholder_name",
            nameEmptyValidationMessage: "validation_name_not_empty"
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



// MARK: - EditSingleInputControllerDelegate

extension ManageItemsUnitsController: EditSingleInputControllerDelegate {
    
    func onSubmitSingleInput(name: String, editingObj: Any?) {
        
        guard let editingUnit = editingObj as? Providers.Unit else {QL4("Invalid state: no editing obj or wrong type: \(editingObj)"); return}
        
        Prov.unitProvider.update(unit: editingUnit, name: name, successHandler{[weak self] in
            self?.topEditSectionControllerManager?.expand(false)
            self?.tableView.reloadData()
        })
    }
}
