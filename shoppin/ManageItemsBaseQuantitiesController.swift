//
//  ManageItemsBaseQuantitiesController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers


protocol ManageItemsBaseQuantitiesControllerDelegate: class {
    var topControllerConfig: ManageDatabaseTopControllerConfig {get}
    
}

class ManageItemsBaseQuantitiesController: UITableViewController, SearchableTextController {
    
    fileprivate var bases: [Float]?
    
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSingleInputController>?
    
    weak var delegate: ManageItemsControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterItems(str: "")
        
        if let delegate = delegate {
            topEditSectionControllerManager = initSimpleInputControllerManager(config: delegate.topControllerConfig)
        } else {
            logger.e("Can't initialize top controller: No delegate")
        }
    }
    
    fileprivate func initSimpleInputControllerManager(config: ManageDatabaseTopControllerConfig) -> ExpandableTopViewController<EditSingleInputController> {
        let manager: ExpandableTopViewController<EditSingleInputController> = ExpandableTopViewController(top: config.top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: config.animateInset, parentViewController: config.parentController, tableView: tableView) {[weak self] _ in
            let controller = EditSingleInputController()
            controller.delegate = self
            return controller
        }
        manager.delegate = config.delegate
        return manager
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bases?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let bases = bases else {logger.e("No brands"); return UITableViewCell()}
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ManageItemsBaseQuantityCell
        
        cell.config(base: bases[indexPath.row], filter: delegate?.currentFilter)
        
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
            
            guard let bases = bases else {logger.e("No bases"); return}
            
            // Removing base is equivalent to remove products with base, base doesn't exist outside of products.
            Prov.productProvider.deleteProductsWith(base: bases[indexPath.row], successHandler{[weak self] in
                self?.bases?.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let bases = bases else {logger.e("No items"); return}
        let base = bases[indexPath.row]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(mode: .standalone, prefillName: base.quantityString, settings: EditSingleInputControllerSettings(
            namePlaceholder: "placeholder_name",
            nameEmptyValidationMessage: "validation_name_not_empty"
        ), editingObj: base, keyboardType: .decimalPad)
        
        //        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    
    // MARK: - SearchableTextController
    
    func filterItems(str: String) {
        Prov.productProvider.baseQuantitiesContainingText(str, successHandler {[weak self] bases in
            self?.bases = bases
            self?.tableView.reloadData()
        })
    }
}



// MARK: - EditSingleInputControllerDelegate

extension ManageItemsBaseQuantitiesController: EditSingleInputControllerDelegate {
    
    func onSubmitSingleInput(name: String, editingObj: Any?) {
        
        guard let base = name.floatValue else { logger.e("Invalid state: input could't be casted to Float - validation should have caught this. Input: \(name)"); return }
        guard let editingBase = editingObj as? Float else { logger.e("Invalid state: no editing obj or wrong type: \(String(describing: editingObj))"); return }

        let finalBase = base > 0 ? base : 1 // 0 base doesn't make sense - convert to 1

        Prov.productProvider.updateBaseQuantity(oldBase: editingBase, newBase: finalBase, successHandler{[weak self] in
            self?.topEditSectionControllerManager?.expand(false)
            
            //self?.tableView.reloadData()
            
            // We aren't using Realm results in this controller but an array so we have to reload the data manually. TODO use Realm Results
            self?.filterItems(str: self?.delegate?.currentFilter ?? "")
        })
    }
}
