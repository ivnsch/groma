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
        var dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.loadLists()
        })
    }
  
    private func addList(listInput: ListInput) {
        let list = List(uuid: NSUUID().UUIDString, name: listInput.name)
        
        self.listItemsProvider.add(list, handler: {try in
           
            if let addedList = try.success {
                self.loadLists() // we modified list - reload everything
                self.selectTableViewRow(addedList)
            
            } else {
                println("Error: couldn't add list to provider: \(list)")
            }
        })
    }
    
    private func selectTableViewRow(list: List) {
        if let rowIndex = find(selectables.map{$0.model}, list) {
            self.tableView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: false)
            
        } else {
            println("Warning: trying to select a list that is not in the tableview")
        }
    }
   
    private func restoreSelectionAfterReloadData() {
        if let selectedList = self.selectedList {
            self.selectTableViewRow(selectedList)
        }
    }
    
    private func loadLists() {
        self.listItemsProvider.lists{[weak self] try in
            if let lists = try.success {
                self?.selectables = lists.map{Selectable(model: $0)}
                self?.tableView.reloadData()
            }
        }
    }

    private func selectList(list: List) {
        self.selectedList = list
        self.selectTableViewRow(list) // this makes sense when selecting programmatically and is redundant when we come from selecting in table view (ok).
        
        self.delegate?.listSelected(list)
    }
    
    private func removeList(list: List) {
        self.listItemsProvider.remove(list, handler: {[weak self] removed in
            if removed.success ?? false {
                self?.loadLists()
                self?.restoreSelectionAfterReloadData()
                
            } else {
                println("Error: list couldn't be removed: \(list)")
            }
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
            println("Error - cell without list tapped")
        }
    }

}
