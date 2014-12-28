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
    
    private(set) var sections:[Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    private(set) var items:[ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style:ListItemsTableViewControllerStyle = .Normal
    
    private var swipedTableViewListItem:TableViewListItem?
    
    var tableViewTopInset:CGFloat {
        set {
            self.tableView.contentInset = UIEdgeInsetsMake(newValue, 0, 0, 0)
            
            //TODO do we need this
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
        }
        get {
            return self.tableView.contentInset.top
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
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
//        tapGesture.numberOfTapsRequired = 2
//        self.tableView.addGestureRecognizer(tapGesture)
        
//        self.tableView.allowsMultipleSelectionDuringEditing = false
    }
    
    
    override func viewWillLayoutSubviews() {
//        println(self.view.constraints().count)
    }
    
    private func initTableView() {
//        self.tableView.registerClass(ListItemCell.self, forCellReuseIdentifier: ItemsListTableViewConstants.listItemCellIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
//        self.tableView.setEditing(true, animated: true)
    }
    
    func setListItems(items:[ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
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
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    // assumes the items are grouped by section (items with section A, then items with section B, etc.)
    private func buildTableViewSections(listItems:[ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
        var tableViewSections:[ListItemsViewSection] = []
        var sections:[Section] = []
        
        if !listItems.isEmpty {
            var set = [Section: Int]() // a "set" for quick lookup which sections we added already
            
            //we don't need to initialise this variable here but compiler complains otherwise...
            var currentTableViewSection:ListItemsViewSection = ListItemsViewSection(section: listItems.first!.section, tableViewListItems: [])
            
            //go through all the items, create new section when we find one, add following items to the current section until we find new one
            //o(n)
            for listItem in listItems {
                
                let tableViewListItem = TableViewListItem(listItem: listItem)
                
                if set[listItem.section] == nil {
                    set[listItem.section] = 1 // dummy value... swift doesn't have Set
                    sections.append(listItem.section)
                    
                    currentTableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [])
                    currentTableViewSection.delegate = self

                    if self.style == .Gray {
                        currentTableViewSection.style = .Gray
                    }
                    tableViewSections.append(currentTableViewSection)
                }
                currentTableViewSection.addItem(tableViewListItem)
            }
        }
        
        return (tableViewSections, sections)
    }
    
    // TODO return bool
    func removeListItem(listItem:ListItem, animation:UITableViewRowAnimation) {
        
        if let indexPath = self.getIndexPath(listItem) {
            
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
    
//    // TODO return bool
//    func removeListItem(listItem:ListItem, animation:UITableViewRowAnimation) {
//        if let indexPath = self.getIndexPath(listItem) {
//            self.removeListItem(listItem, animation: animation)
//        }
//    }
    
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
    
    func handleTapGesture(sender:UITapGestureRecognizer) {
        let tapLocation = sender.locationInView(self.tableView)
        let indexPathMaybe:NSIndexPath? = self.tableView.indexPathForRowAtPoint(tapLocation)
        
        if let indexPath = indexPathMaybe {
            let tableViewListItem:TableViewListItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
            listItemsTableViewDelegate?.onListItemClear(tableViewListItem)
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
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
    
//    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return UITableViewCellEditingStyle.Delete
//    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            //            self.toggleItemDone(self.sections[indexPath.section].listItems[indexPath.row])
        }
    }
    
//    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return UITableViewCellEditingStyle.None
//    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        
    }
    
//    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
//        return NSIndexPath()
//    }

}
