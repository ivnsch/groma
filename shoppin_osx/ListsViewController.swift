//
//  ListsViewController.swift
//  shoppin
//
//  Created by ischuetz on 07/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol ListsViewControllerDelegate: class {
    func listSelected(list: List)
}

class ListsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, ListCellDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
 
    private let listItemsProvider = ProviderFactory().listItemProvider
    private let listsProvider = ProviderFactory().listProvider
    
    private var selectables: [Selectable<List>] = []
    
    weak var delegate: ListsViewControllerDelegate?
    
    private(set) var selectedList: List?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tableView.headerView = nil
    }
    
    @IBAction func addListTapped(sender: NSButton) {
        let addListController = AddListController()
        addListController.addTappedFunc = {listInput in
            self.addList(listInput)
            addListController.close()
        }
        addListController.show()
    }
    
    override func viewDidAppear() {
        self.loadLists() // note we have to do this in viewDidAppear (or later) otherwise crash because tableview delegate seems not to be fully initialised yet. Related with being created in other view controller.
        if let firstList = self.selectables.first?.model {
            self.selectList(firstList)
            self.selectTableViewRow(firstList)
        }
        
        // temporary workaround for recreation of icloud folder
        let seconds = 3.0
        let delay = seconds * Double(NSEC_PER_SEC)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.loadLists()
        })
    }
  
    private func addList(listInput: EditListInput) {
        let list = List(uuid: NSUUID().UUIDString, name: listInput.name)
        
        // TODO handle when user doesn't have account! if I add list without internet, then there's no account data and no possibility to share users
        // so in this case we add to local database with dummy user (?) that represents myself and hide share users from the user (or "you need an account to use this")
        // when user opens account with lists like that, somehow we replace the dummy value with the email (client and server)
        // or maybe we can just use *always* a dummy identifier for myself. A general purpose string like "myself"
        // For the user is not important to see their own email address, only to know this is myself. This is probably a bad idea for the databse in the server though.
        let listWithSharedUsers = ListWithSharedUsersInput(list: list, users: [SharedUserInput(email: "foo@foo.foo")])
        
        self.listsProvider.add(listWithSharedUsers, successHandler{[weak self] addedList in
            self?.loadLists() // we modified list - reload everything
            self?.selectTableViewRow(addedList)
            return
        })
    }
    
    private func selectTableViewRow(list: List) {
        if let rowIndex = (selectables.map{$0.model}).indexOf(list) {
            self.tableView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: false)
        } else {
            print("Warning: trying to select a list that is not in the tableview")
        }
    }
   
    private func restoreSelectionAfterReloadData() {
        if let selectedList = self.selectedList {
            self.selectTableViewRow(selectedList)
        }
    }
    
    private func loadLists() {
        self.listItemsProvider.lists(successHandler{[weak self] lists in
            self?.selectables = lists.map{Selectable(model: $0)}
            self?.tableView.reloadData()
        })
    }

    private func selectList(list: List) {
        self.selectedList = list
        self.selectTableViewRow(list) // this makes sense when selecting programmatically and is redundant when we come from selecting in table view (ok).
        
        self.delegate?.listSelected(list)
    }
    
    private func removeList(list: List) {
        self.listItemsProvider.remove(list, successHandler{[weak self] in
            self?.loadLists()
            self?.restoreSelectionAfterReloadData()
        })
    }
    
    private func removeListWithConfirm(list: List) {
        DialogUtils.confirmAlert(okTitle: "Yes", title: "Remove list: \(list.name)\nAre you sure?", msg: "This will also delete all the items in the list", okAction: {
            self.removeList(list)
        })
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.selectables.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("listCell", owner:self) as! ListCell
        let selectable = self.selectables[row]
        cell.list = selectable.model
        cell.delegate = self
        return cell
    }
   
    func tableViewSelectionDidChange(notification: NSNotification) {
        let row = self.tableView.selectedRow
        if row >= 0 {
            let selectedList = self.selectables[row].model
            self.selectList(selectedList)
        }
    }
    
    // MARK: - ListCellDelegate
    
    func removeListTapped(cell: ListCell) {
        if let list = cell.list {
            self.removeListWithConfirm(list)
            
        } else {
            print("Error - cell without list tapped")
        }
    }

}
