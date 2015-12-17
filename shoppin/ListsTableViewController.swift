//
//  ExpandableTableViewListModel.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ExpandableTableViewListModel: ExpandableTableViewModel {
    
    let list: List
    
    init (list: List) {
        self.list = list
    }
    
    override var name: String {
        return list.name
    }
    
    override var bgColor: UIColor {
        return list.bgColor
    }
    
    override var users: [SharedUser] {
        return list.users
    }
    
    override func same(rhs: ExpandableTableViewModel) -> Bool {
        return list.same((rhs as! ExpandableTableViewListModel).list)
    }
}

class ListsTableViewController: ExpandableItemsTableViewController, AddEditListControllerDelegate {

    var topAddEditListControllerManager: ExpandableTopViewController<AddEditListController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketList:", name: WSNotificationName.List.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditListController> {
        let top = CGRectGetHeight(topBar.frame)
        return ExpandableTopViewController(top: top, height: 250, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditList()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = true
            return controller
        }
    }
    
    override func initModels() {
        Providers.listProvider.lists(successHandler{lists in
            let models: [ExpandableTableViewModel] = lists.map{ExpandableTableViewListModel(list: $0)}
            if self.models != models { // if current list is nil or the provider list is different
                self.models = models
                self.tableView.reloadData()
            }
        })
    }

    private func initNavBarRightButtons(actions: [UIBarButtonSystemItem]) {
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                self.addButton = button
                buttons.append(button)
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            case .Cancel:
                let button = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancelTap:")
                buttons.append(button)
            default: break
            }
        }
        
        topBar.items?.first?.rightBarButtonItems = buttons
    }
    
    override func onCancelTap(sender: UIBarButtonItem) {
        super.onCancelTap(sender)
        topAddEditListControllerManager?.expand(false)
    }
    
    override func onSubmitTap(sender: UIBarButtonItem) {
        topAddEditListControllerManager?.controller?.submit()
    }

    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewListModel).list
        topAddEditListControllerManager?.expand(true)
    }

    override func onReorderedModels() {
        let lists = (models as! [ExpandableTableViewListModel]).map{$0.list}
        
        let updatedLists = lists.mapEnumerate{index, list in list.copy(order: index)}

        Providers.listProvider.update(updatedLists, remote: true, successHandler{
//            self?.models = models // REVIEW remove? this seem not be necessary...
        })
    }
    
    override func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.todoItemsViewController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true

        listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
            listItemsController.setThemeColor(cell.backgroundColor!)
            listItemsController.currentList = (model as! ExpandableTableViewListModel).list
            listItemsController.onExpand(true)
        }

        return listItemsController
    }

    override func onAddTap() {
        topAddEditListControllerManager?.expand(!(topAddEditListControllerManager?.expanded ?? true)) // toggle - if for some reason variable isn't set, set expanded false (!true)
    }
    
    override func closeTopViewController() {
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - EditListViewController
    //sub?
    func onListAdded(list: List) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewListModel(list: list))
                self?.topAddEditListControllerManager?.expand(false)
                self?.initNavBarRightButtons([.Add])
            }
        }
    }

    func onListUpdated(list: List) {
        models.update(ExpandableTableViewListModel(list: list))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - Websocket
    
    func onWebsocketList(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<List>> {
            if let notification = info[WSNotificationValue] {

                let list = notification.obj

                switch notification.verb {
                case .Add:
                    Providers.listProvider.add(list, remote: false, successHandler {[weak self] savedList in
                        self?.onListAdded(savedList)
                    })

                case .Update:
                    Providers.listProvider.update(list, remote: false, successHandler{[weak self] in
                        self?.onListUpdated(list)
                    })

                case .Delete:
                    Providers.listProvider.remove(list, remote: false, successHandler{[weak self] in
                        self?.removeModel(ExpandableTableViewListModel(list: list))
                    })
                }
            } else {
                print("Error: ViewController.onWebsocketList: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketList: no userInfo")
        }
    }
}