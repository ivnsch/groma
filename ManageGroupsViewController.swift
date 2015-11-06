//
//  ManageGroupsViewController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ManageGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, ManageGroupsAddEditControllerDelegate {

    private var editButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

    @IBOutlet weak var searchBar: UISearchBar!
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var groups: [ListItemGroup] = [] {
        didSet {
            filteredGroups = ItemWithCellAttributes.toItemsWithCellAttributes(groups)
        }
    }
    
    private var filteredGroups: [ItemWithCellAttributes<ListItemGroup>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initNavBar()
        
        tableView.allowsSelectionDuringEditing = true
        
        Providers.listItemGroupsProvider.groups(successHandler {[weak self] groups in
            self?.groups = groups
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        groups = []
        paginator.reset()
        loadPossibleNextPage()
    }

    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar() {
        navigationItem.title = "Manage groups"
        let editButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
        self.editButton = editButton
        navigationItem.setRightBarButtonItem(editButton, animated: true)
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredGroups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell", forIndexPath: indexPath) as! ManageGroupsCell
        
        let group = filteredGroups[indexPath.row]
        
        cell.group = group
        return cell
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let group = filteredGroups[indexPath.row]
            
            Providers.listItemGroupsProvider.remove(group.item, successHandler{[weak self] in
                self?.tableView.wrapUpdates {
                    self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    self?.groups.remove(group.item)
                    self?.filteredGroups.remove(group)
                }
            })
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredGroups = ItemWithCellAttributes.toItemsWithCellAttributes(groups)
        } else {
            Providers.listItemGroupsProvider.groupsContainingText(searchText, successHandler{[weak self] groups in
                let groupsWithCellAttributes = groups.map{group in
                    return ItemWithCellAttributes(item: group, boldRange: group.name.range(searchText, caseInsensitive: true))
                }
                self?.filteredGroups = groupsWithCellAttributes
            })
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredGroups = ItemWithCellAttributes.toItemsWithCellAttributes(groups)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let group = groups[indexPath.row]
        showAddEditController(group)
    }
    
    private func showAddEditController(editingGroup: ListItemGroup? = nil) {
        let addEditController = UIStoryboard.manageGroupsAddEditController()
        addEditController.editingGroup = editingGroup
        addEditController.delegate = self
        addEditController.navigationItem.title = editingGroup == nil ? "Add" : "Edit"
        navigationController?.pushViewController(addEditController, animated: true)
    }
    
    // MARK: - ManageGroupsAddEditControllerDelegate
    
    func onGroupCreated(group: ListItemGroup) {
        groups.append(group)
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: groups.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
        navigationController?.popViewControllerAnimated(true)
    }
    
    func onGroupUpdated(group: ListItemGroup) {
        groups.update(group)
        navigationController?.popViewControllerAnimated(true)
    }
    
    func onGroupItemsOpen() {
        // do nothing
    }
    
    func onGroupItemsSubmit() {
        // do nothing
    }
    
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }

        tableView.setEditing(editing, animated: animated)
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }

    func onAddTap(sender: UIBarButtonItem) {
        clearSearch() // clear filter to avoid confusion, if we add a group it may be not in current filter and user will not see it appearing.
        showAddEditController()
    }
    
    
    // For now not used, user can delete by swipe & confirm. And edit items by just tapping on them
    func onEditTap(sender: UIBarButtonItem) {
//        setEditing(!self.editing, animated: true)
//        groupsController.setEditing(self.editing, animated: true)
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    Providers.listItemGroupsProvider.groups(weakSelf.paginator.currentPage, weakSelf.successHandler{groups in
                        weakSelf.groups.appendAll(groups)
                        
                        weakSelf.paginator.update(groups.count)
                        
                        weakSelf.tableView.reloadData()
                        setLoading(false)
                    })
                }
            }
        }
    }
}

