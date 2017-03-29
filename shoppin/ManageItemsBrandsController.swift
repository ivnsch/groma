//
//  ManageItemsBrandsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers
import QorumLogs

protocol ManageItemsBrandsControllerDelegate: SearchableItemsControllersDelegate {
    var topControllerConfig: ManageDatabaseTopControllerConfig {get}
    
}

class ManageItemsBrandsController: UITableViewController, SearchableTextController {
    
    fileprivate var brands: [String]?
    
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSingleInputController>?
    
    weak var delegate: ManageItemsControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterItems(str: "")
        
        if let delegate = delegate {
            topEditSectionControllerManager = initSimpleInputControllerManager(config: delegate.topControllerConfig)
        } else {
            QL4("Can't initialize top controller: No delegate")
        }
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
        return brands?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let brands = brands else {QL4("No brands"); return UITableViewCell()}
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ManageItemsBrandCell
        
        cell.config(brand: brands[indexPath.row], filter: delegate?.currentFilter)
        
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
            
            guard let brands = brands else {QL4("No brands"); return}
            
            // Removing brand is equivalent to remove products with brand, brand doesn't exist outside of products.
            Prov.brandProvider.removeProductsWithBrand(brands[indexPath.row], remote: true, successHandler{[weak self] in
                self?.brands?.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let brands = brands else {QL4("No items"); return}
        let brand = brands[indexPath.row]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(mode: .standalone, prefillName: brand, settings: EditSingleInputControllerSettings(
            namePlaceholder: "placeholder_name",
            nameEmptyValidationMessage: "validation_name_not_empty"
        ), editingObj: brand)
        
        //        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    // MARK: - SearchableTextController
    
    func filterItems(str: String) {
        Prov.brandProvider.brandsContainingText(str, successHandler {[weak self] brands in
            self?.brands = brands
            self?.tableView.reloadData()
        })
    }
}



// MARK: - AddEditNameNameColorControllerDelegate

extension ManageItemsBrandsController: EditSingleInputControllerDelegate {

    func onSubmitSingleInput(name: String, editingObj: Any?) {
        
        guard let editingBrand = editingObj as? String else {QL4("Invalid state: no editing obj or wrong type: \(String(describing: editingObj))"); return}
        
        Prov.brandProvider.updateBrand(editingBrand, newName: name, successHandler{[weak self] in
            self?.topEditSectionControllerManager?.expand(false)
            self?.tableView.reloadData()
        })
    }
}
