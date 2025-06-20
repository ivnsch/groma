//
//  ManageItemsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers


struct ManageDatabaseTopControllerConfig {
    var top: CGFloat
    var animateInset: Bool
    var parentController: UIViewController
    var delegate: ExpandableTopViewControllerDelegate
}

protocol ManageItemsControllerDelegate: SearchableItemsControllersDelegate {
    var topControllerConfig: ManageDatabaseTopControllerConfig {get}
    
}

class ManageItemsController: UITableViewController, SearchableTextController {

    fileprivate var items: Results<Item>?
    fileprivate var realmData: RealmData?

    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<AddEditNameNameColorController>?

    weak var delegate: ManageItemsControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterItems(str: "")

        tableView.backgroundColor = Theme.defaultTableViewBGColor

        if let delegate = delegate {
            topEditSectionControllerManager = initEditSectionControllerManager(config: delegate.topControllerConfig)
        } else {
            logger.e("Can't initialize top controller: No delegate")
        }
    }
    
    fileprivate func load() {
        Prov.itemsProvider.items(sortBy: .alphabetic, successHandler{[weak self] items in
            self?.items = items
            self?.initNotifications()
        })
    }
    
    fileprivate func initNotifications() {
        guard let items = items else {logger.e("No sections"); return}
        guard let realm = items.realm else {logger.e("No realm"); return}
        
        realmData?.invalidateTokens()
        
        let notificationToken = items.observe {changes in
            
            switch changes {
            case .initial: break
            case .update(_, let deletions, let insertions, let modifications):
                logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                // TODO
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        realmData = RealmData(realm: realm, token: notificationToken)
    }
    
    fileprivate func initEditSectionControllerManager(config: ManageDatabaseTopControllerConfig) -> ExpandableTopViewController<AddEditNameNameColorController> {
        let manager: ExpandableTopViewController<AddEditNameNameColorController> = ExpandableTopViewController(top: config.top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: config.animateInset, parentViewController: config.parentController, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.addEditNameNameColorController()
            controller.delegate = self
            return controller
        }
        manager.delegate = config.delegate
        return manager
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let items = items else {logger.e("No items"); return UITableViewCell()}
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ManageItemsItemCell
        
        cell.config(item: items[indexPath.row], filter: delegate?.currentFilter)
        
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

            guard let items = items else {logger.e("No items"); return}
            guard let realmData = realmData else {logger.e("No realm data"); return}
            
            Prov.itemsProvider.delete(itemUuid: items[indexPath.row].uuid, realmData: realmData, successHandler{[weak self] in
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let items = items else {logger.e("No items"); return}
        let item = items[indexPath.row]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(prefillData: AddEditNameNameColorControllerInputs(
            name: item.name,
            buttonSelected: item.edible,
            nameColorName: item.category.name,
            nameColorColor: item.category.color
            
            ), settings: AddEditNameNameColorControllerSettings(
                namePlaceholder: trans("placeholder_name"),
                nameEmptyValidationMessage: trans("validation_name_not_empty"),
                buttonTitle: trans("edible_button_title"),
                nameNameColorPlaceholder: trans("placeholder_category_name"),
                nameNameColorEmptyValidationMessage: trans("validation_category_name_not_empty")
                
            ), editingObj: item
        )
        //        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    // MARK: - SearchableTextController
    
    func filterItems(str: String) {
        Prov.itemsProvider.items(str, onlyEdible: false, range: NSRange(location: 0, length: 100000), sortBy: .alphabetic, successHandler({[weak self] tuple in
//            if tuple.substring == weakSelf.searchText {}
            self?.items = tuple.items
            self?.initNotifications()
            self?.tableView.reloadData()
        }))
    }
}



// MARK: - AddEditNameNameColorControllerDelegate

extension ManageItemsController: AddEditNameNameColorControllerDelegate {
    
    func onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult) {
        let itemInput = ItemInput(name: result.name, categoryName: result.nameColorInputs.name, categoryColor: result.nameColorInputs.color, edible: result.buttonSelected)
        Prov.itemsProvider.addOrUpdate(input: itemInput, successHandler {[weak self] _ in
            self?.tableView.reloadData()
            self?.topEditSectionControllerManager?.expand(false)
        })
    }
}
