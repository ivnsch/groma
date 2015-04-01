//
//  ListItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemsTableViewDelegate {
    func onListItemClear(tableViewListItem:TableViewListItem)
    func onListItemSelected(tableViewListItem:TableViewListItem)
}

protocol ListItemsEditTableViewDelegate {
    func onListItemsChangedSection(tableViewListItems:[TableViewListItem])
    func onListItemDeleted(tableViewListItem:TableViewListItem)
}

enum ListItemsTableViewControllerStyle {
    case Normal, Gray
}

class ListItemsTableViewController: UITableViewController, UIScrollViewDelegate, ItemActionsDelegate {
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section
    private var tableViewSections:[ListItemsViewSection] = []
    
    private var lastContentOffset:CGFloat = 0
    
    var scrollViewDelegate:UIScrollViewDelegate?
    var listItemsTableViewDelegate:ListItemsTableViewDelegate?
    var listItemsEditTableViewDelegate:ListItemsEditTableViewDelegate?

    private(set) var sections:[Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    private(set) var items:[ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style:ListItemsTableViewControllerStyle = .Normal
    
    private var swipedTableViewListItem:TableViewListItem?
    
    var tableViewInset:UIEdgeInsets {
        set {
            self.tableView.contentInset = newValue
            
            //TODO do we need this
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
        }
        get {
            return self.tableView.contentInset
        }
    }
    
    var tableViewTopOffset:CGFloat {
        set {
            self.tableView.contentOffset = CGPointMake(0, newValue)
        }
        get {
            return self.tableView.contentOffset.y
        }
    }
    
    func touchEnabled(enabled:Bool) {
        self.tableView.userInteractionEnabled = enabled
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableView()
        
        //TODO maybe delete with this?
//        self.tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    
    override func viewWillLayoutSubviews() {
//        println(self.view.constraints().count)
    }
    
    private func initTableView() {
//        self.tableView.registerClass(ListItemCell.self, forCellReuseIdentifier: ItemsListTableViewConstants.listItemCellIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        self.tableView.allowsSelectionDuringEditing = true
//        self.tableView.setEditing(true, animated: true)
    }
    
    func setListItems(items:[ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
        self.initTableViewContent()
    }
    
    private func initTableViewContent() {
        let(tableViewSections, sections) = self.buildTableViewSections(self.items)
        self.tableViewSections = tableViewSections
        self.sections = sections
        self.tableView.reloadData()
    }
    
    func addListItem(listItem:ListItem) {
        self.items.append(listItem)
        
        self.addListItemToSection(listItem)
        
        self.tableView.reloadData()
    }
    
    private func addListItemToSection(listItem:ListItem) {
        
        let tableViewListItem = TableViewListItem(listItem: listItem)
        
        let foundSectionMaybe = self.tableViewSections.filter({ (s:ListItemsViewSection) -> Bool in
            s.section == listItem.section
        }).first
        
        if let foundSection = foundSectionMaybe {
            foundSection.addItem(tableViewListItem)
        } else {
            let hasHeader = listItem.section.name != defaultSectionIdentifier
            self.sections.append(listItem.section)
            let tableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [tableViewListItem], hasHeader: hasHeader)
            tableViewSection.delegate = self
            self.tableViewSections.append(tableViewSection)
        }
    }
    
    // TODO simpler way to update, maybe just always reinit the table... also refactor rest (build sections etc) it is way more complex than it should
    // right now prefer not to always reinit the table because this can change sorting
    // so first we should implement persistent sorting, then refactor this class
    func updateListItem(listItem:ListItem) {
        if let indexPath = self.getIndexPath(listItem) {
            let oldItem:TableViewListItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
            if (oldItem.listItem.section == listItem.section) {
                self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row] = TableViewListItem(listItem: listItem)
                self.tableView.reloadData()
            } else { // the item has a different (but present in tableview) section
                //update the list item before we reinit the table, to update the section...
                var itemIndexMaybe:Int?
                for (index, item) in enumerate(self.items) {
                    if item.id == listItem.id {
                        itemIndexMaybe = index
                    }
                }
                if let itemIndex = itemIndexMaybe {
                    self.items[itemIndex] = listItem
                    
                    self.initTableViewContent()
                }
            }
        } else { // indexpath for updated item not in the tableview, this can happen if e.g. updated item has a new section (not in tableview)
            self.items.append(listItem) // FIXME hacky...
            self.initTableViewContent()
        }
    }
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    private func buildTableViewSections(listItems:[ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
        var tableViewSections:[ListItemsViewSection] = []
        var sections:[Section] = []
        
        if !listItems.isEmpty {
            var set = [Section: Int]() // "set" for quick lookup which sections we added already
            

            var currentTableViewSection:ListItemsViewSection!
            
            for listItem in listItems {
                
                let tableViewListItem = TableViewListItem(listItem: listItem)
                
                if set[listItem.section] == nil { // section not created yet - create one
                    set[listItem.section] = 1 // dummy value... swift doesn't have Set
                    sections.append(listItem.section)
                    
                    currentTableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [])
                    currentTableViewSection.delegate = self

                    if self.style == .Gray {
                        currentTableViewSection.style = .Gray
                    }
                    tableViewSections.append(currentTableViewSection)
                    
                } else { //the section is in the set, this means it's in the tableViewSections. find it
                    for tableViewSection in tableViewSections {
                        if tableViewSection.section == listItem.section {
                            currentTableViewSection = tableViewSection
                        }
                    }
                }
                currentTableViewSection.addItem(tableViewListItem)
            }
        }
        
        return (tableViewSections, sections)
    }
    
    // TODO return bool
    func removeListItem(listItem:ListItem, animation:UITableViewRowAnimation) {
        
        if let indexPath = self.getIndexPath(listItem) {
            self.removeListItem(listItem, indexPath: indexPath, animation: animation)
        }
    }
    
    // TODO return bool
    private func removeListItem(listItem:ListItem, indexPath:NSIndexPath, animation:UITableViewRowAnimation) {
        // TODO review this, we store items reduntantely, so find index in one list, remove, use indexPath for the other list....
        // also is it thread safe to pass indexpath like this
        // paramater indexPath and listitem?
        var indexMaybe:Int?
        for i in 0...self.items.count {
            if self.items[i] == listItem {
                indexMaybe = i
                break
            }
        }
        
        if let index = indexMaybe {
            // remove from model
            self.items.removeAtIndex(index)
            let tableViewSection = self.tableViewSections[indexPath.section]
            tableViewSection.tableViewListItems.removeAtIndex(indexPath.row)
            
            // remove from table view
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: animation)
            
            // remove section if no items
            if tableViewSection.tableViewListItems.isEmpty {
                // remove table view section
                self.tableViewSections.removeAtIndex(indexPath.section)
                // remove model section TODO better way
                var sectionIndexMaybe:Int?
                for (index, section) in enumerate(self.sections) {
                    if section == tableViewSection.section {
                        sectionIndexMaybe = index
                    }
                }
                if let sectionIndex = sectionIndexMaybe {
                    self.sections.removeAtIndex(sectionIndex)
                    self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: animation)
                }
            }
            self.tableView.endUpdates()
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        
        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.superview)
        let scrollingUp = (velocity.y < 0)
        
        clearPendingSwipeItemIfAny()
    }
    
    func getIndexPath(listItem:ListItem) -> NSIndexPath? {
        for (sectionIndex, s) in enumerate(self.tableViewSections) {
            for (listItemIndex, l) in enumerate(s.tableViewListItems) {
                if (listItem == l.listItem) {
                    let indexPath = NSIndexPath(forRow: listItemIndex, inSection: sectionIndex)
                    return indexPath
                }
            }
        }
        return nil
    }
    
    
    func clearPendingSwipeItemIfAny() {
        if let s = self.swipedTableViewListItem {
            
            listItemsTableViewDelegate?.onListItemClear(s)
            self.swipedTableViewListItem = nil
//            self.removeListItem(s.listItem, animation: UITableViewRowAnimation.Bottom)
        }
    }
    
    func startItemSwipe(tableViewListItem: TableViewListItem) {
        clearPendingSwipeItemIfAny()
    }
    
    func endItemSwipe(tableViewListItem: TableViewListItem) {
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//            }.reduce([], combine: +)
        
        self.swipedTableViewListItem = tableViewListItem
    }
    
    func undoSwipe(tableViewListItem: TableViewListItem) {
        self.swipedTableViewListItem = nil
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.editing
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForHeader()
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForFooter()
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForFooter())
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForHeader())
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewSections[section].numberOfRows()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.tableViewSections.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = self.tableViewSections[indexPath.section]
        return section.heightForRow(indexPath.row)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = self.tableViewSections[indexPath.section]
        return section.tableView(tableView, row:indexPath.row)
        
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tableViewListItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
        self.listItemsTableViewDelegate?.onListItemSelected(tableViewListItem)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            self.tableView.beginUpdates()

            // remove from tableview and model
            let listItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
            self.removeListItem(listItem.listItem, indexPath: indexPath, animation: UITableViewRowAnimation.Bottom)
            
            // remove from content provider
            self.listItemsEditTableViewDelegate?.onListItemDeleted(listItem)
            
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.editing
    }
   
    // updates list item models with current ordering in table view
    private func updateListItemsModelsOrder() {
        var sectionRows = 0
        for section in self.tableViewSections {
            for (listItemIndex, tableViewListItem) in enumerate(section.tableViewListItems) {
                let absoluteRowIndex = listItemIndex + sectionRows
                tableViewListItem.listItem.order = absoluteRowIndex
            }
            sectionRows += section.numberOfRows()
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let srcSection = self.tableViewSections[sourceIndexPath.section]
        let tableViewListItem = srcSection.tableViewListItems[sourceIndexPath.row]
        srcSection.tableViewListItems.removeAtIndex(sourceIndexPath.row)
        
        let dstSection = self.tableViewSections[destinationIndexPath.section]
        tableViewListItem.listItem.section = dstSection.section //not superclean to update model data in this controller, but for simplicity...
        
        let absoluteRow = tableView.absoluteRow(destinationIndexPath)
        dstSection.tableViewListItems.insert(tableViewListItem, atIndex: destinationIndexPath.row)

        self.updateListItemsModelsOrder()
        
        self.listItemsEditTableViewDelegate?.onListItemsChangedSection(self.tableViewSections.flatMap{$0.tableViewListItems})
    }
}
