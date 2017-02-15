//
//  ManageItemsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers
import QorumLogs

class ManageItemsController: UIViewController {

    fileprivate var tableViewController: UITableViewController!
    fileprivate var tableView: UITableView! {
        return tableViewController.tableView
    }
    
    fileprivate var items: Results<Item>?
    fileprivate var realmData: RealmData?

    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<AddEditNameNameColorController>?

    override func viewDidLoad() {
        super.viewDidLoad()

        load()
        
        topEditSectionControllerManager = initEditSectionControllerManager()

        addEditButton()
    }
    
    fileprivate func initEditSectionControllerManager() -> ExpandableTopViewController<AddEditNameNameColorController> {
        let top: CGFloat = 0 // we currently use the system's nav bar so there's no offset (view controller starts below it)
        let manager: ExpandableTopViewController<AddEditNameNameColorController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: true, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditNameNameColorController()
            controller.delegate = self
            return controller
        }
//        manager.delegate = self
        return manager
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
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        realmData = RealmData(realm: realm, token: notificationToken)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destination as? UITableViewController
            tableViewController?.tableView.dataSource = self
            tableViewController?.tableView.delegate = self
            
            tableViewController?.tableView.backgroundColor = Theme.defaultTableViewBGColor
            
            tableViewController?.tableView.reloadData()
        }
    }
    
    deinit {
        QL1("Deinit mange items controller")
    }
    
    
    // MARK: - Editing
    
    fileprivate func addEditButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "tb_edit"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onEditTap(_:)))
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableViewController.setEditing(editing, animated: animated)
    }
    
    func onEditTap(_ sender: UIBarButtonItem) {
        setEditing(!isEditing, animated: true)
    }
}



extension ManageItemsController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ManageItemsItemCell
        
        if let items = items {
            cell.config(item: items[indexPath.row])
        } else {
            QL4("Illegal state: No item for row: \(indexPath.row)")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.ingredientsCellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let items = items else {QL4("No items"); return}
            guard let realmData = realmData else {QL4("No realm data"); return}
            
            Prov.itemsProvider.delete(itemUuid: items[indexPath.row].uuid, realmData: realmData, successHandler{[weak self] in
                self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard isEditing else {return} TODO expand top only during editing
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
}

// MARK: - EditSectionViewControllerDelegate

extension ManageItemsController: AddEditNameNameColorControllerDelegate {
    
    func onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult) {
        print("Submitted result: \(result)")
        // TODO
    }
}
