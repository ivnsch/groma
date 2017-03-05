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
import QorumLogs

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
        
        if let delegate = delegate {
            topEditSectionControllerManager = initEditSectionControllerManager(config: delegate.topControllerConfig)
        } else {
            QL4("Can't initialize top controller: No delegate")
        }
    }
    
    fileprivate func load() {
        Prov.itemsProvider.items(sortBy: .alphabetic, successHandler{[weak self] items in
            self?.items = items
            self?.initNotifications()
        })
    }
    
    fileprivate func initNotifications() {
        guard let items = items else {QL4("No sections"); return}
        guard let realm = items.realm else {QL4("No realm"); return}
        
        realmData?.token.stop()
        
        let notificationToken = items.addNotificationBlock {changes in
            
            switch changes {
            case .initial: break
            case .update(_, let deletions, let insertions, let modifications):
                QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                // TODO
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        realmData = RealmData(realm: realm, token: notificationToken)
    }
    
    fileprivate func initEditSectionControllerManager(config: ManageDatabaseTopControllerConfig) -> ExpandableTopViewController<AddEditNameNameColorController> {
        let manager: ExpandableTopViewController<AddEditNameNameColorController> = ExpandableTopViewController(top: config.top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: config.animateInset, parentViewController: config.parentController, tableView: tableView) {[weak self] in
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
        
        guard let items = items else {QL4("No items"); return UITableViewCell()}
        
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
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            guard let items = items else {QL4("No items"); return}
            guard let realmData = realmData else {QL4("No realm data"); return}
            
            Prov.itemsProvider.delete(itemUuid: items[indexPath.row].uuid, realmData: realmData, successHandler{[weak self] in
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let items = items else {QL4("No items"); return}
        let item = items[indexPath.row]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(prefillData: AddEditNameNameColorControllerInputs(
            name: item.name,
            nameColorName: item.category.name,
            nameColorColor: item.category.color
            
            // TODO!!!!!!!!!!!!!!!!!!! translations
            ), settings: AddEditNameNameColorControllerSettings(
                namePlaceholder: "placeholder_name",
                nameEmptyValidationMessage: "validation_name_not_empty",
                nameNameColorPlaceholder: "placeholder_category_name",
                nameNameColorEmptyValidationMessage: "validation_category_name_not_empty"
                
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
        print("Submitted result: \(result)")
        // TODO
    }
}
